-- Server-side quota for the costly editorial/image-generation Edge Function.
create table if not exists public.card_assistant_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('text', 'illustration')),
  requested_at timestamptz not null default now()
);

create index if not exists card_assistant_requests_user_time_idx
  on public.card_assistant_requests (user_id, requested_at desc);

alter table public.card_assistant_requests enable row level security;
revoke all privileges on table public.card_assistant_requests from public, anon, authenticated;

create or replace function public.consume_card_assistant_quota(p_action text)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  u uuid := auth.uid();
  p public.profiles;
  requests_last_hour integer;
  illustrations_last_hour integer;
begin
  if u is null then raise exception 'auth required'; end if;
  if p_action not in ('text', 'illustration') then raise exception 'invalid action'; end if;

  select * into p from public.profiles where id = u;
  if p.id is null or p.is_suspended or p.role not in ('admin'::public.app_role, 'catalog_manager'::public.app_role) then
    raise exception 'forbidden';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text, 0));

  delete from public.card_assistant_requests
   where user_id = u and requested_at < now() - interval '24 hours';

  select count(*) into requests_last_hour
    from public.card_assistant_requests
   where user_id = u and requested_at >= now() - interval '1 hour';

  if requests_last_hour >= 30 then raise exception 'rate limit exceeded'; end if;

  if p_action = 'illustration' then
    select count(*) into illustrations_last_hour
      from public.card_assistant_requests
     where user_id = u and action = 'illustration'
       and requested_at >= now() - interval '1 hour';
    if illustrations_last_hour >= 5 then raise exception 'illustration rate limit exceeded'; end if;
  end if;

  insert into public.card_assistant_requests(user_id, action) values (u, p_action);
end
$function$;

revoke all on function public.consume_card_assistant_quota(text) from public, anon;
grant execute on function public.consume_card_assistant_quota(text) to authenticated;
