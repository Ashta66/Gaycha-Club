-- Limit direct profile reads to fields intended for public/community use.
-- Private profile fields are exposed only through an authenticated, self-scoped RPC.

create or replace function public.get_my_profile()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $function$
  select jsonb_build_object(
    'username', p.username,
    'balance', p.balance,
    'age_confirmed_at', p.age_confirmed_at,
    'role', p.role,
    'is_suspended', p.is_suspended,
    'xp', p.xp
  )
  from public.profiles as p
  where p.id = (select auth.uid());
$function$;

revoke all on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;

revoke select on table public.profiles from anon, authenticated;
grant select (id, username, bio, xp, created_at)
  on table public.profiles to anon, authenticated;
