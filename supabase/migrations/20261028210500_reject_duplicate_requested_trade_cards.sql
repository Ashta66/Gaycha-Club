-- Reject duplicate requested card types in a trade offer. Without this check,
-- an offer can be created that can never be fulfilled by accept_trade.
create or replace function public.propose_trade(
  p_recipient text,
  p_give uuid[],
  p_get uuid[],
  p_offer_coins bigint default 0,
  p_request_coins bigint default 0
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
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
  select * into pr from public.profiles where id = u;
  if pr.is_suspended or pr.age_confirmed_at is null then raise exception 'forbidden'; end if;
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
$function$;
