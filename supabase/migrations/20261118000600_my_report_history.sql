create or replace function public.get_my_report_history()
returns table (
  id uuid,
  reason text,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select r.id, r.reason, r.status, r.created_at
  from public.reports r
  where auth.uid() is not null
    and r.reporter_id = auth.uid()
  order by r.created_at desc
  limit 100;
$function$;

revoke all on function public.get_my_report_history() from public, anon;
grant execute on function public.get_my_report_history() to authenticated;
