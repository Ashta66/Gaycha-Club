-- Keep uploaded member avatars private and make report queue actions auditable.
update storage.buckets set public = false where id = 'avatars';

drop policy if exists avatars_select_owner_or_admin on storage.objects;
create policy avatars_select_owner_or_admin
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or public.is_staff(array['admin']::public.app_role[])
  )
);

create or replace function public.admin_set_report_status(p_report uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_report public.reports;
begin
  if auth.uid() is null
     or not public.is_staff(array['admin','moderator']::public.app_role[]) then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if p_report is null or p_status is null or p_status not in ('open','reviewed','dismissed') then
    raise exception 'invalid report status' using errcode = '22023';
  end if;

  update public.reports
     set status = p_status
   where id = p_report
   returning * into v_report;

  if not found then
    raise exception 'report not found' using errcode = 'P0002';
  end if;

  perform public.log_audit(
    'report.status',
    jsonb_build_object(
      'report_id', v_report.id,
      'reporter_id', v_report.reporter_id,
      'reported_user_id', v_report.reported_user_id,
      'message_id', v_report.message_id,
      'status', v_report.status
    )
  );
end;
$function$;

revoke all on function public.admin_set_report_status(uuid, text) from public, anon;
grant execute on function public.admin_set_report_status(uuid, text) to authenticated;
