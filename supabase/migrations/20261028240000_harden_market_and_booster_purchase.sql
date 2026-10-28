create or replace function public.buy_listing(p_listing uuid, p_key text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  l public.market_listings;
  b public.profiles;
  s public.profiles;
  inst public.card_instances;
  fee_pct numeric;
  fee bigint;
  net bigint;
begin
  if u is null then raise exception 'auth required'; end if;
  if p_key is null or char_length(btrim(p_key)) < 8 or char_length(p_key) > 200 then raise exception 'invalid request key'; end if;
  select * into l from public.market_listings where id = p_listing for update;
  if l.id is null or l.status <> 'active' then raise exception 'listing unavailable'; end if;
  if l.seller_id = u then raise exception 'cannot buy own listing'; end if;
  if exists (select 1 from public.ledger where idempotency_key = p_key) then raise exception 'duplicate request'; end if;
  perform 1 from public.profiles where id in (u, l.seller_id) order by id for update;
  select * into b from public.profiles where id = u;
  select * into s from public.profiles where id = l.seller_id;
  if b.is_suspended or b.age_confirmed_at is null or s.is_suspended then raise exception 'forbidden'; end if;
  if b.balance < l.price then raise exception 'insufficient funds'; end if;
  select * into inst from public.card_instances where id = l.instance_id for update;
  if inst.id is null or inst.owner_id <> l.seller_id then raise exception 'listing invalid'; end if;
  select coalesce((select value::numeric from public.app_settings where key = 'market_fee_percent'), 0) into fee_pct;
  fee := floor(l.price * fee_pct / 100);
  net := l.price - fee;
  update public.profiles set balance = balance - l.price where id = u;
  update public.profiles set balance = balance + net where id = l.seller_id;
  insert into public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
  values (u, -l.price, 'market:buy', l.id, b.balance - l.price, p_key);
  insert into public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
  values (l.seller_id, net, 'market:sale', l.id, s.balance + net, p_key || ':seller');
  update public.card_instances set owner_id = u, locked = false, acquired_at = now() where id = inst.id;
  update public.market_listings set status = 'sold', buyer_id = u, sold_at = now() where id = l.id;
end
$function$;
revoke all on function public.buy_listing(uuid, text) from public, anon;
grant execute on function public.buy_listing(uuid, text) to authenticated;

create or replace function public.buy_booster(p_slug text, p_key text)
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  pr public.profiles;
  b public.booster_types;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id = u for update;
  if pr.id is null or pr.is_suspended or pr.age_confirmed_at is null then raise exception 'forbidden'; end if;
  if p_key is null or char_length(btrim(p_key)) < 8 or char_length(p_key) > 200 then raise exception 'invalid request key'; end if;
  if exists (select 1 from public.ledger where idempotency_key = p_key) then raise exception 'duplicate request'; end if;
  select * into b from public.booster_types where slug = p_slug and active;
  if b.id is null then raise exception 'unknown booster'; end if;
  if b.cooldown_hours > 0 and exists (
    select 1 from public.ledger where user_id = u
      and reason in ('booster_purchase:' || b.slug, 'booster:' || b.slug)
      and created_at > now() - make_interval(hours => b.cooldown_hours)
  ) then raise exception 'cooldown active'; end if;
  if pr.balance < b.price then raise exception 'insufficient funds'; end if;
  update public.profiles set balance = balance - b.price where id = u;
  insert into public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
  values (u, -b.price, 'booster_purchase:' || b.slug, b.id, pr.balance - b.price, p_key);
  insert into public.booster_inventory(user_id, booster_type_id, paid_quantity, updated_at)
  values (u, b.id, 1, now())
  on conflict (user_id, booster_type_id)
  do update set paid_quantity = public.booster_inventory.paid_quantity + 1, updated_at = now();
  perform public.log_audit('booster.purchase', jsonb_build_object('user', u, 'slug', b.slug, 'price', b.price));
  return (select paid_quantity from public.booster_inventory where user_id = u and booster_type_id = b.id);
end
$function$;
revoke all on function public.buy_booster(text, text) from public, anon;
grant execute on function public.buy_booster(text, text) to authenticated;
