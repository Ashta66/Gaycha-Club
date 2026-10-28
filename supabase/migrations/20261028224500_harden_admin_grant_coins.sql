create or replace function public.admin_grant_coins(p_username text, p_amount bigint, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  t public.profiles;
  clean_reason text := btrim(coalesce(p_reason, ''));
begin
  if u is null or not public.is_staff(array['admin']::public.app_role[]) then
    raise exception 'forbidden';
  end if;

  if p_amount is null or p_amount < 1 or p_amount > 1000 then
    raise exception 'amount must be 1..1000';
  end if;

  if char_length(clean_reason) < 5 or char_length(clean_reason) > 500 then
    raise exception 'reason must be 5..500 characters';
  end if;

  select *
    into t
    from public.profiles
   where lower(username) = lower(btrim(coalesce(p_username, '')))
   for update;

  if t.id is null then
    raise exception 'unknown user';
  end if;

  update public.profiles
     set balance = balance + p_amount
   where id = t.id;

  insert into public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
  values (t.id, p_amount, 'admin_grant', u, t.balance + p_amount, 'grant:' || gen_random_uuid()::text);

  perform public.log_audit(
    'coins.grant',
    jsonb_build_object('user', t.id, 'username', t.username, 'amount', p_amount, 'reason', clean_reason)
  );
end
$function$;

revoke all on function public.admin_grant_coins(text, bigint, text) from public, anon;
grant execute on function public.admin_grant_coins(text, bigint, text) to authenticated;
