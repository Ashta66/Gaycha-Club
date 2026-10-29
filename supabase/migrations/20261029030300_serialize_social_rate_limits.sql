-- Serialize per-user rate and pending-offer checks to prevent concurrent bypasses.
CREATE OR REPLACE FUNCTION public.propose_trade(p_recipient text, p_give uuid[], p_get uuid[], p_offer_coins bigint DEFAULT 0, p_request_coins bigint DEFAULT 0)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  u uuid := auth.uid();
  pr public.profiles;
  rc public.profiles;
  oid uuid;
  n int := 0;
  g uuid;
  i record;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id = u for update;
  if pr.id is null or pr.is_suspended is distinct from false or pr.age_confirmed_at is null then
    raise exception 'forbidden';
  end if;
  select * into rc from public.profiles where lower(username) = lower(p_recipient);
  if rc.id is null or rc.id = u or rc.is_suspended then raise exception 'unknown recipient'; end if;

  p_give := coalesce(p_give, '{}');
  p_get := coalesce(p_get, '{}');
  p_offer_coins := coalesce(p_offer_coins, 0);
  p_request_coins := coalesce(p_request_coins, 0);
  if p_offer_coins < 0 or p_request_coins < 0 then raise exception 'invalid coins'; end if;
  if cardinality(p_give) + cardinality(p_get) + p_offer_coins + p_request_coins = 0 then raise exception 'empty offer'; end if;
  if cardinality(p_give) > 5 or cardinality(p_get) > 5 then raise exception 'too many cards'; end if;
  if (select count(distinct x) from unnest(p_give) x) <> cardinality(p_give) then raise exception 'duplicate instance'; end if;
  if (select count(distinct x) from unnest(p_get) x) <> cardinality(p_get) then raise exception 'duplicate requested card'; end if;
  if (select count(*) from public.trade_offers where proposer_id = u and status = 'pending') >= 10 then raise exception 'too many pending offers'; end if;

  insert into public.trade_offers(proposer_id, recipient_id, offer_coins, request_coins)
  values(u, rc.id, p_offer_coins, p_request_coins) returning id into oid;

  for i in select id, card_id from public.card_instances
    where id = any(p_give) and owner_id = u and not locked for update
  loop
    update public.card_instances set locked = true where id = i.id;
    insert into public.trade_items(offer_id, side, instance_id, card_id) values(oid, 'give', i.id, i.card_id);
    n := n + 1;
  end loop;
  if n <> cardinality(p_give) then raise exception 'some cards unavailable'; end if;

  foreach g in array p_get loop
    if not exists(select 1 from public.cards where id = g and status = 'publie') then raise exception 'unknown card'; end if;
    insert into public.trade_items(offer_id, side, card_id) values(oid, 'get', g);
  end loop;
  return oid;
end
$function$
;

CREATE OR REPLACE FUNCTION public.send_message(p_recipient text, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  u uuid := auth.uid();
  pr public.profiles;
  rc public.profiles;
  cv public.conversations;
  mid uuid;
  body text := btrim(coalesce(p_body, ''));
begin
  if u is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id = u for update;
  if pr.id is null or pr.is_suspended is distinct from false or pr.age_confirmed_at is null then
    raise exception 'forbidden';
  end if;
  if char_length(body) not between 1 and 1000 then raise exception 'invalid message'; end if;
  select * into rc from public.profiles where lower(username) = lower(p_recipient);
  if rc.id is null or rc.id = u or rc.is_suspended then raise exception 'cannot message this user'; end if;
  if exists(select 1 from public.blocks where (blocker_id = u and blocked_id = rc.id) or (blocker_id = rc.id and blocked_id = u)) then
    raise exception 'cannot message this user';
  end if;
  if (select count(*) from public.messages where sender_id = u and created_at > now() - interval '1 minute') >= 10 then
    raise exception 'rate limit: wait a moment';
  end if;
  select * into cv from public.conversations
  where user_a = least(u, rc.id) and user_b = greatest(u, rc.id) for update;
  if cv.id is null then
    if (select count(*) from public.conversations where requested_by = u and status = 'pending') >= 20 then
      raise exception 'too many pending requests';
    end if;
    insert into public.conversations(user_a, user_b, requested_by)
    values(least(u, rc.id), greatest(u, rc.id), u) returning * into cv;
  elsif cv.status = 'declined' then
    raise exception 'cannot message this user';
  elsif cv.status = 'pending' then
    if cv.requested_by <> u then raise exception 'accept the request first';
    elsif exists(select 1 from public.messages where conversation_id = cv.id) then raise exception 'waiting for acceptance'; end if;
  end if;
  insert into public.messages(conversation_id, sender_id, body) values(cv.id, u, body) returning id into mid;
  return mid;
end
$function$
;
