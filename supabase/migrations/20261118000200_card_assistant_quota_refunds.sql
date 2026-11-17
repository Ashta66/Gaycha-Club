-- Reserve image-generation quota atomically and refund it when the provider fails.
-- The existing text-generation quota remains unchanged.
create or replace function public.reserve_card_assistant_quota(p_action text)
returns bigint
language plpgsql
security definer
set search_path to ''
as $function$
declare
  u uuid := auth.uid();
  p public.profiles;
  requests_last_hour integer;
  illustrations_last_hour integer;
  request_id bigint;
begin
  if u is null then raise exception 'auth required'; end if;
  if p_action <> 'illustration' then raise exception 'invalid action'; end if;

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

  select count(*) into illustrations_last_hour
    from public.card_assistant_requests
   where user_id = u and action = 'illustration'
     and requested_at >= now() - interval '1 hour';
  if illustrations_last_hour >= 5 then raise exception 'illustration rate limit exceeded'; end if;

  insert into public.card_assistant_requests(user_id, action)
  values (u, 'illustration')
  returning id into request_id;

  return request_id;
end
$function$;

revoke all on function public.reserve_card_assistant_quota(text) from public, anon;
grant execute on function public.reserve_card_assistant_quota(text) to authenticated;

create or replace function public.release_card_assistant_quota(p_request_id bigint)
returns boolean
language plpgsql
security definer
set search_path to ''
as $function$
declare
  u uuid := auth.uid();
  p public.profiles;
  deleted_count integer;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into p from public.profiles where id = u;
  if p.id is null or p.is_suspended or p.role not in ('admin'::public.app_role, 'catalog_manager'::public.app_role) then
    raise exception 'forbidden';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text, 0));

  delete from public.card_assistant_requests
   where id = p_request_id
     and user_id = u
     and action = 'illustration'
     and requested_at >= now() - interval '30 minutes';
  get diagnostics deleted_count = row_count;

  return deleted_count = 1;
end
$function$;

revoke all on function public.release_card_assistant_quota(bigint) from public, anon;
grant execute on function public.release_card_assistant_quota(bigint) to authenticated;
