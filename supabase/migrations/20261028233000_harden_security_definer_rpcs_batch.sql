create or replace function public.is_staff(r public.app_role[])
returns boolean language sql stable security definer set search_path = ''
as $function$
  select exists (select 1 from public.profiles where id = auth.uid() and role = any(r) and not is_suspended)
$function$;
revoke all on function public.is_staff(public.app_role[]) from public;
grant execute on function public.is_staff(public.app_role[]) to anon, authenticated;

create or replace function public.admin_reports()
returns table(id uuid, reason text, status text, created_at timestamptz, reporter text, reported text, body text)
language plpgsql security definer set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.is_staff(array['admin','moderator']::public.app_role[]) then raise exception 'forbidden'; end if;
  return query select r.id, r.reason, r.status, r.created_at, p1.username, p2.username, m.body
    from public.reports r join public.profiles p1 on p1.id = r.reporter_id
    join public.profiles p2 on p2.id = r.reported_user_id join public.messages m on m.id = r.message_id
    order by (r.status = 'open') desc, r.created_at desc limit 100;
end
$function$;
revoke all on function public.admin_reports() from public, anon;
grant execute on function public.admin_reports() to authenticated;

create or replace function public.admin_stats()
returns jsonb language plpgsql security definer set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.is_staff(array['admin','moderator','catalog_manager']::public.app_role[]) then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'comptes', (select count(*) from public.profiles),
    'comptes_suspendus', (select count(*) from public.profiles where is_suspended),
    'exemplaires_de_cartes', (select count(*) from public.card_instances),
    'cartes_publiees', (select count(*) from public.cards where status = 'publie'),
    'annonces_actives', (select count(*) from public.market_listings where status = 'active'),
    'echanges_en_attente', (select count(*) from public.trade_offers where status = 'pending'),
    'signalements_ouverts', (select count(*) from public.reports where status = 'open'),
    'monnaie_en_circulation', (select coalesce(sum(balance), 0) from public.profiles));
end
$function$;
revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;

create or replace function public.block_user(p_username text)
returns void language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid(); t uuid;
begin
  if u is null then raise exception 'auth required'; end if;
  select id into t from public.profiles where lower(username) = lower(p_username);
  if t is null or t = u then raise exception 'unknown user'; end if;
  insert into public.blocks(blocker_id, blocked_id) values(u, t) on conflict do nothing;
  update public.conversations set status = 'declined' where user_a = least(u,t) and user_b = greatest(u,t) and status = 'pending';
end
$function$;
revoke all on function public.block_user(text) from public, anon;
grant execute on function public.block_user(text) to authenticated;

create or replace function public.cancel_listing(p_listing uuid)
returns void language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid(); l public.market_listings;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into l from public.market_listings where id = p_listing for update;
  if l.id is null or l.seller_id <> u or l.status <> 'active' then raise exception 'listing unavailable'; end if;
  update public.market_listings set status = 'cancelled' where id = l.id;
  update public.card_instances set locked = false where id = l.instance_id;
end
$function$;
revoke all on function public.cancel_listing(uuid) from public, anon;
grant execute on function public.cancel_listing(uuid) to authenticated;

create or replace function public.close_trade(p_offer uuid, p_as text)
returns void language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid(); o public.trade_offers;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into o from public.trade_offers where id = p_offer for update;
  if o.id is null or o.status <> 'pending' then raise exception 'offer unavailable'; end if;
  if p_as = 'decline' and o.recipient_id = u then
    update public.trade_offers set status = 'declined', resolved_at = now() where id = o.id;
  elsif p_as = 'cancel' and o.proposer_id = u then
    update public.trade_offers set status = 'cancelled', resolved_at = now() where id = o.id;
  else raise exception 'not allowed'; end if;
  update public.card_instances set locked = false where id in (select instance_id from public.trade_items where offer_id = o.id and side = 'give');
end
$function$;
revoke all on function public.close_trade(uuid, text) from public, anon;
grant execute on function public.close_trade(uuid, text) to authenticated;

create or replace function public.confirm_age()
returns void language sql security definer set search_path = ''
as $function$ update public.profiles set age_confirmed_at = now() where id = auth.uid() and age_confirmed_at is null; $function$;
revoke all on function public.confirm_age() from public, anon;
grant execute on function public.confirm_age() to authenticated;

create or replace function public.list_card(p_instance uuid, p_price bigint)
returns uuid language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid(); pr public.profiles; i public.card_instances; lid uuid;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id = u;
  if pr.is_suspended or pr.age_confirmed_at is null then raise exception 'forbidden'; end if;
  if p_price is null or p_price < 1 or p_price > 1000000 then raise exception 'invalid price'; end if;
  select * into i from public.card_instances where id = p_instance for update;
  if i.id is null or i.owner_id <> u then raise exception 'not your card'; end if;
  if i.locked then raise exception 'card already engaged'; end if;
  update public.card_instances set locked = true where id = i.id;
  insert into public.market_listings(seller_id, instance_id, price) values(u, i.id, p_price) returning id into lid;
  return lid;
end
$function$;
revoke all on function public.list_card(uuid, bigint) from public, anon;
grant execute on function public.list_card(uuid, bigint) to authenticated;

create or replace function public.mark_read(p_conversation uuid)
returns void language sql security definer set search_path = ''
as $function$
  update public.messages set read_at = now()
  where conversation_id = p_conversation and sender_id <> auth.uid() and read_at is null
    and exists(select 1 from public.conversations c where c.id = p_conversation and auth.uid() in (c.user_a, c.user_b));
$function$;
revoke all on function public.mark_read(uuid) from public, anon;
grant execute on function public.mark_read(uuid) to authenticated;

create or replace function public.report_message(p_message uuid, p_reason text)
returns void language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid(); m public.messages;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into m from public.messages where id = p_message;
  if m.id is null or m.sender_id = u or not exists(select 1 from public.conversations c where c.id = m.conversation_id and u in (c.user_a, c.user_b)) then raise exception 'message unavailable'; end if;
  if char_length(btrim(coalesce(p_reason,''))) not between 3 and 500 then raise exception 'invalid reason'; end if;
  insert into public.reports(reporter_id, message_id, reported_user_id, reason) values(u, m.id, m.sender_id, btrim(p_reason)) on conflict do nothing;
end
$function$;
revoke all on function public.report_message(uuid, text) from public, anon;
grant execute on function public.report_message(uuid, text) to authenticated;

create or replace function public.unblock_user(p_blocked uuid)
returns void language sql security definer set search_path = ''
as $function$ delete from public.blocks where blocker_id = auth.uid() and blocked_id = p_blocked; $function$;
revoke all on function public.unblock_user(uuid) from public, anon;
grant execute on function public.unblock_user(uuid) to authenticated;
