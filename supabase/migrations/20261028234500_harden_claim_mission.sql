create or replace function public.claim_mission(p_slug text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  u uuid := auth.uid();
  m public.missions;
  pr public.profiles;
  pk text;
  prog integer;
  since timestamptz;
begin
  if u is null then raise exception 'auth required'; end if;
  select * into pr from public.profiles where id = u for update;
  if pr.id is null or pr.is_suspended or pr.age_confirmed_at is null then raise exception 'forbidden'; end if;
  select * into m from public.missions where slug = p_slug and active;
  if m.id is null then raise exception 'unknown mission'; end if;
  if m.kind = 'daily' then
    pk := to_char(now() at time zone 'utc', 'YYYY-MM-DD');
    since := date_trunc('day', now() at time zone 'utc') at time zone 'utc';
  else
    pk := to_char(now() at time zone 'utc', 'IYYY-"W"IW');
    since := date_trunc('week', now() at time zone 'utc') at time zone 'utc';
  end if;
  if exists (select 1 from public.mission_claims where user_id = u and mission_id = m.id and period_key = pk) then
    raise exception 'already claimed';
  end if;
  if m.metric = 'boosters_opened' then
    select count(*) into prog from public.ledger
    where user_id = u and (reason like 'booster:%' or reason like 'booster_gift:%' or reason like 'booster_paid:%')
      and created_at >= since;
    if prog < m.goal then raise exception 'mission not completed (% / %)', prog, m.goal; end if;
  elsif m.metric = 'login' then
    -- An authenticated, eligible session satisfies the login mission.
    null;
  else
    raise exception 'unsupported mission metric';
  end if;
  insert into public.mission_claims(user_id, mission_id, period_key) values (u, m.id, pk);
  insert into public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
  values (u, m.reward, 'mission:' || m.slug, m.id, pr.balance + m.reward,
          'mission:' || u::text || ':' || m.id::text || ':' || pk);
  update public.profiles set balance = balance + m.reward, xp = xp + m.xp_reward where id = u;
end
$function$;
revoke all on function public.claim_mission(text) from public, anon;
grant execute on function public.claim_mission(text) to authenticated;
