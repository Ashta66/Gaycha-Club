-- Privacy rights: authenticated members can request account deletion without triggering destructive cascades.
create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  status text not null default 'pending' check (status in ('pending','reviewing','completed','rejected')),
  requested_at timestamptz not null default now(),
  handled_at timestamptz,
  admin_note text
);
create index if not exists account_deletion_requests_user_created_idx
  on public.account_deletion_requests(user_id, requested_at desc);
create unique index if not exists account_deletion_requests_one_open_per_user
  on public.account_deletion_requests(user_id)
  where status in ('pending','reviewing');
alter table public.account_deletion_requests enable row level security;
revoke all on public.account_deletion_requests from anon, public;
grant select, insert on public.account_deletion_requests to authenticated;
drop policy if exists account_deletion_requests_read_own on public.account_deletion_requests;
create policy account_deletion_requests_read_own
  on public.account_deletion_requests for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists account_deletion_requests_insert_own on public.account_deletion_requests;
create policy account_deletion_requests_insert_own
  on public.account_deletion_requests for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'pending'
    and handled_at is null
    and admin_note is null
    and length(coalesce(reason,'')) <= 500
  );
drop policy if exists account_deletion_requests_admin_read on public.account_deletion_requests;
create policy account_deletion_requests_admin_read
  on public.account_deletion_requests for select to authenticated
  using (public.is_staff(array['admin'::public.app_role]));
drop policy if exists account_deletion_requests_admin_update on public.account_deletion_requests;
create policy account_deletion_requests_admin_update
  on public.account_deletion_requests for update to authenticated
  using (public.is_staff(array['admin'::public.app_role]))
  with check (public.is_staff(array['admin'::public.app_role]));
create or replace function public.request_account_deletion(p_reason text default null)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then
    raise exception 'Authentification requise.' using errcode='42501';
  end if;
  if length(coalesce(p_reason,'')) > 500 then
    raise exception 'La précision ne peut pas dépasser 500 caractères.' using errcode='22023';
  end if;
  select id into v_id
  from public.account_deletion_requests
  where user_id = v_user and status in ('pending','reviewing')
  order by requested_at desc limit 1;
  if v_id is not null then return v_id; end if;
  insert into public.account_deletion_requests(user_id,reason)
  values (v_user,nullif(btrim(p_reason),''))
  returning id into v_id;
  return v_id;
end;
$function$;
revoke all on function public.request_account_deletion(text) from public, anon;
grant execute on function public.request_account_deletion(text) to authenticated;
