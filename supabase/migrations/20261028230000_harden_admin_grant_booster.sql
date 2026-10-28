create or replace function public.admin_grant_booster(p_quantity integer, p_reason text, p_slug text, p_username text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  actor_id uuid := auth.uid();
  target public.profiles;
  bt public.booster_types;
  clean_reason text := btrim(coalesce(p_reason, ''));
begin
  if actor_id is null or not public.is_staff(array['admin']::public.app_role[]) then
    raise exception 'forbidden';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 20 then
    raise exception 'quantity must be 1..20';
  end if;

  if char_length(clean_reason) < 5 or char_length(clean_reason) > 500 then
    raise exception 'reason must be 5..500 characters';
  end if;

  select *
    into target
    from public.profiles
   where lower(username) = lower(btrim(coalesce(p_username, '')))
   for update;

  if target.id is null then
    raise exception 'unknown user';
  end if;

  if target.is_suspended then
    raise exception 'cannot grant boosters to a suspended account';
  end if;

  select *
    into bt
    from public.booster_types
   where slug = p_slug;

  if bt.id is null then
    raise exception 'unknown booster';
  end if;

  insert into public.booster_inventory(user_id, booster_type_id, quantity, updated_at)
  values (target.id, bt.id, p_quantity, now())
  on conflict (user_id, booster_type_id)
  do update
     set quantity = public.booster_inventory.quantity + excluded.quantity,
         updated_at = now();

  perform public.log_audit(
    'booster.grant',
    jsonb_build_object('user', target.id, 'username', target.username, 'slug', bt.slug,
                       'quantity', p_quantity, 'reason', clean_reason)
  );
end
$function$;

revoke all on function public.admin_grant_booster(integer, text, text, text) from public, anon;
grant execute on function public.admin_grant_booster(integer, text, text, text) to authenticated;
