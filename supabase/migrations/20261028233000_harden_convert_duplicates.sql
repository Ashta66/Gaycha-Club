create or replace function public.convert_duplicates(p_card uuid, p_qty integer, p_key text)
returns bigint
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  pr public.profiles;
  r public.rarity;
  v bigint;
  total integer;
  ids uuid[];
  gain bigint;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id = u for update;
  if pr.id is null or pr.is_suspended or pr.age_confirmed_at is null then raise exception 'forbidden'; end if;
  if p_qty is null or p_qty < 1 then raise exception 'invalid quantity'; end if;
  if p_key is null or char_length(btrim(p_key)) < 8 or char_length(p_key) > 200 then raise exception 'invalid idempotency key'; end if;
  if exists (select 1 from public.ledger where idempotency_key = p_key) then raise exception 'duplicate request'; end if;
  select rarity into r from public.cards where id = p_card;
  if r is null then raise exception 'unknown card'; end if;
  select count(*) into total from public.card_instances where owner_id = u and card_id = p_card;
  if total - p_qty < 1 then raise exception 'must keep one copy'; end if;
  select array_agg(id) into ids from (
    select id from public.card_instances where owner_id = u and card_id = p_card and not locked
    order by acquired_at desc limit p_qty
  ) t;
  if coalesce(array_length(ids, 1), 0) < p_qty then raise exception 'not enough unlocked copies'; end if;
  select value into v from public.duplicate_values where rarity = r;
  gain := coalesce(v, 0) * p_qty;
  delete from public.card_instances where id = any(ids);
  insert into public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
  values (u, gain, 'duplicates', p_card, pr.balance + gain, p_key);
  update public.profiles set balance = balance + gain where id = u;
  return gain;
end
$function$;
revoke all on function public.convert_duplicates(uuid, integer, text) from public, anon;
grant execute on function public.convert_duplicates(uuid, integer, text) to authenticated;
