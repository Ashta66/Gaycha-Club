create or replace function public.admin_dashboard_detail(p_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_activity jsonb;v_audit jsonb;v_reports integer;v_trades integer;v_suspended integer;
begin
 if auth.uid() is null or not public.is_staff(array['admin','moderator','catalog_manager']::public.app_role[]) then raise exception 'forbidden' using errcode='42501';end if;
 if p_days is null or p_days not in (7,30,90) then raise exception 'invalid period' using errcode='22023';end if;
 select coalesce(jsonb_agg(jsonb_build_object(
   'day',to_char(d.day,'YYYY-MM-DD'),
   'new_accounts',(select count(*) from public.profiles p where p.created_at::date=d.day::date),
   'cards_acquired',(select count(*) from public.card_instances ci where ci.acquired_at::date=d.day::date),
   'boosters_opened',(select count(*) from public.ledger l where l.created_at::date=d.day::date and (l.reason like 'booster:%' or l.reason like 'booster_gift:%' or l.reason like 'booster_paid:%')),
   'credit_delta',(select coalesce(sum(l.delta),0) from public.ledger l where l.created_at::date=d.day)
 ) order by d.day),'[]'::jsonb) into v_activity
 from generate_series(current_date-(p_days-1),current_date,interval '1 day') as d(day);
 select count(*)::integer into v_reports from public.reports where status='open';
 select count(*)::integer into v_trades from public.trade_offers where status='pending';
 select count(*)::integer into v_suspended from public.profiles where is_suspended;
 if public.is_staff(array['admin']::public.app_role[]) then
  select coalesce(jsonb_agg(jsonb_build_object('action',x.action,'actor',coalesce(p.username,'Système'),'created_at',x.created_at) order by x.created_at desc),'[]'::jsonb) into v_audit
  from (select actor,action,created_at from public.audit_log order by created_at desc limit 8) x left join public.profiles p on p.id=x.actor;
 else v_audit:='[]'::jsonb;end if;
 return jsonb_build_object('days',p_days,'activity',v_activity,'alerts',jsonb_build_object('open_reports',v_reports,'pending_trades',v_trades,'suspended_accounts',v_suspended),'audit',coalesce(v_audit,'[]'::jsonb));
end;$$;
revoke all on function public.admin_dashboard_detail(integer) from public,anon;
grant execute on function public.admin_dashboard_detail(integer) to authenticated;
