create or replace function public.admin_set_suspension(p_username text, p_suspend boolean, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  actor public.profiles;
  t public.profiles;
begin
  if u is null or not public.is_staff(array['admin','moderator']::public.app_role[]) then
    raise exception 'forbidden';
  end if;
  select * into actor from public.profiles where id = u;
  select * into t from public.profiles where lower(username) = lower(p_username);
  if t.id is null or t.id = u then raise exception 'unknown or not allowed'; end if;
  if t.role = 'admin' then raise exception 'cannot suspend an admin'; end if;
  if t.role <> 'user' and actor.role <> 'admin' then raise exception 'forbidden'; end if;
  if char_length(btrim(coalesce(p_reason, ''))) < 3 then raise exception 'reason required'; end if;
  update public.profiles set is_suspended = p_suspend where id = t.id;
  perform public.log_audit(case when p_suspend then 'user.suspend' else 'user.restore' end,
    jsonb_build_object('user', t.id, 'username', t.username, 'reason', btrim(p_reason)));
end
$function$;
revoke all on function public.admin_set_suspension(text, boolean, text) from public, anon;
grant execute on function public.admin_set_suspension(text, boolean, text) to authenticated;

create or replace function public.admin_set_booster(p_slug text, p_odds jsonb, p_price bigint, p_pity integer, p_cooldown integer, p_active boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  old public.booster_types;
  total numeric := 0;
  k text;
begin
  if u is null or not public.is_staff(array['admin']::public.app_role[]) then raise exception 'forbidden'; end if;
  select * into old from public.booster_types where slug = p_slug;
  if old.id is null then raise exception 'unknown booster'; end if;
  foreach k in array array['commun','peu_commun','rare','epique','legendaire','secrete'] loop
    if not (p_odds ? k) or (p_odds->>k)::numeric < 0 then raise exception 'missing or invalid odds for %', k; end if;
    total := total + (p_odds->>k)::numeric;
  end loop;
  if abs(total - 100) > 0.001 then raise exception 'odds must sum to 100 (got %)', total; end if;
  if p_price < 0 or p_pity < 1 or p_cooldown < 0 then raise exception 'invalid values'; end if;
  update public.booster_types set odds = p_odds, price = p_price, pity_threshold = p_pity,
    cooldown_hours = p_cooldown, active = p_active where slug = p_slug;
  perform public.log_audit('booster.update', jsonb_build_object('slug', p_slug, 'old', to_jsonb(old),
    'new', jsonb_build_object('odds', p_odds, 'price', p_price, 'pity', p_pity,
                              'cooldown', p_cooldown, 'active', p_active)));
end
$function$;
revoke all on function public.admin_set_booster(text, jsonb, bigint, integer, integer, boolean) from public, anon;
grant execute on function public.admin_set_booster(text, jsonb, bigint, integer, integer, boolean) to authenticated;

create or replace function public.admin_resolve_report(p_report uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or not public.is_staff(array['admin','moderator']::public.app_role[]) then raise exception 'forbidden'; end if;
  if p_status not in ('reviewed','dismissed') then raise exception 'invalid status'; end if;
  update public.reports set status = p_status where reports.id = p_report and reports.status = 'open';
  if not found then raise exception 'report unavailable'; end if;
  perform public.log_audit('report.' || p_status, jsonb_build_object('report', p_report));
end
$function$;
revoke all on function public.admin_resolve_report(uuid, text) from public, anon;
grant execute on function public.admin_resolve_report(uuid, text) to authenticated;
