-- Harden the conversation-request response RPC.
-- Explicitly reject a missing auth identity and remove the mutable search path.
create or replace function public.respond_request(p_conversation uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  cv public.conversations;
begin
  if u is null then
    raise exception 'auth required';
  end if;

  select *
    into cv
    from public.conversations
   where id = p_conversation
   for update;

  if cv.id is null
     or cv.status <> 'pending'
     or cv.requested_by = u
     or u not in (cv.user_a, cv.user_b) then
    raise exception 'request unavailable';
  end if;

  update public.conversations
     set status = case when p_accept then 'accepted' else 'declined' end
   where id = cv.id;
end
$function$;

revoke all on function public.respond_request(uuid, boolean) from public, anon;
grant execute on function public.respond_request(uuid, boolean) to authenticated;
