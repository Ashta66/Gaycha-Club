create or replace function public.attempt_secret_challenge(p_slug text, p_answer text)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid(); ch public.secret_challenges; normalized text; ok boolean := false; card_row public.cards;
begin
  if u is null then raise exception 'auth required'; end if;
  if length(coalesce(p_slug,'')) > 80 or length(coalesce(p_answer,'')) > 120 then raise exception 'invalid input'; end if;
  if not exists(select 1 from public.profiles p where p.id=u and p.age_confirmed_at is not null and not p.is_suspended) then raise exception 'forbidden'; end if;
  select * into ch from public.secret_challenges where slug=p_slug and active;
  if ch.id is null then raise exception 'unknown challenge'; end if;
  if exists(select 1 from public.secret_discoveries d where d.user_id=u and d.challenge_id=ch.id) then return jsonb_build_object('ok',true,'already',true,'message','Secret déjà découvert.'); end if;
  if (select count(*) from public.secret_attempts a where a.user_id=u and a.challenge_id=ch.id and a.attempted_at > now()-interval '1 hour') >= 8 then raise exception 'too many attempts; try again later'; end if;
  normalized := regexp_replace(lower(btrim(coalesce(p_answer,''))), '[^a-z0-9]', '', 'g');
  ok := encode(extensions.digest(normalized, 'sha256'), 'hex') = ch.answer_digest;
  insert into public.secret_attempts(user_id,challenge_id,correct) values(u,ch.id,ok);
  if not ok then return jsonb_build_object('ok',false,'message','Ce n’est pas encore ça. Relis l’indice et retente ta chance.'); end if;
  insert into public.secret_discoveries(user_id,challenge_id,reward_card_id) values(u,ch.id,ch.reward_card_id) on conflict(user_id,challenge_id) do nothing;
  select * into card_row from public.cards where id=ch.reward_card_id;
  if card_row.id is not null and not exists(select 1 from public.card_instances i where i.owner_id=u and i.card_id=card_row.id) then insert into public.card_instances(card_id,owner_id) values(card_row.id,u); end if;
  return jsonb_build_object('ok',true,'already',false,'message','Secret découvert ! Une nouvelle carte rejoint ta collection.','card_id',ch.reward_card_id);
end
$function$;
revoke all on function public.attempt_secret_challenge(text, text) from public, anon;
grant execute on function public.attempt_secret_challenge(text, text) to authenticated;

create or replace function public.list_secret_challenges()
returns table(slug text, title text, clue text, hint text, solved boolean)
language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'auth required'; end if;
  if not exists(select 1 from public.profiles p where p.id=u and p.age_confirmed_at is not null and not p.is_suspended) then raise exception 'forbidden'; end if;
  return query select ch.slug,ch.title,ch.clue,ch.hint,exists(select 1 from public.secret_discoveries d where d.user_id=u and d.challenge_id=ch.id)
    from public.secret_challenges ch where ch.active order by ch.created_at;
end
$function$;
revoke all on function public.list_secret_challenges() from public, anon;
grant execute on function public.list_secret_challenges() to authenticated;

create or replace function public.expire_offers()
returns void language plpgsql security definer set search_path = ''
as $function$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'auth required'; end if;
  with expired as (update public.trade_offers set status='expired',resolved_at=now() where status='pending' and expires_at<now() and (proposer_id=u or recipient_id=u) returning id)
  update public.card_instances set locked=false where id in (select ti.instance_id from public.trade_items ti where ti.side='give' and ti.offer_id in (select id from expired));
end
$function$;
revoke all on function public.expire_offers() from public, anon;
grant execute on function public.expire_offers() to authenticated;

create or replace function public.my_missions()
returns table(slug text,title text,kind text,reward bigint,xp_reward integer,goal integer,progress integer,claimed boolean)
language plpgsql stable security definer set search_path = ''
as $function$
declare u uuid:=auth.uid(); m public.missions; pk text; since timestamptz; prog int;
begin
  if u is null then raise exception 'auth required'; end if;
  for m in select * from public.missions where active order by kind,reward loop
    if m.kind='daily' then pk:=to_char(now() at time zone 'utc','YYYY-MM-DD'); since:=date_trunc('day',now() at time zone 'utc') at time zone 'utc';
    else pk:=to_char(now() at time zone 'utc','IYYY-"W"IW'); since:=date_trunc('week',now() at time zone 'utc') at time zone 'utc'; end if;
    if m.metric='boosters_opened' then select count(*) into prog from public.ledger l where l.user_id=u and l.reason like 'booster:%' and l.created_at>=since;
    else prog:=m.goal; end if;
    slug:=m.slug; title:=m.title; kind:=m.kind; reward:=m.reward; xp_reward:=m.xp_reward; goal:=m.goal; progress:=least(prog,m.goal);
    claimed:=exists(select 1 from public.mission_claims mc where mc.user_id=u and mc.mission_id=m.id and mc.period_key=pk);
    return next;
  end loop;
end
$function$;
revoke all on function public.my_missions() from public, anon;
grant execute on function public.my_missions() to authenticated;

create or replace function public.log_audit(p_action text,p_details jsonb)
returns void language sql security definer set search_path = ''
as $function$ insert into public.audit_log(actor,action,details) values(auth.uid(),p_action,p_details); $function$;
revoke all on function public.log_audit(text,jsonb) from public, anon, authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  insert into public.profiles(id,username)
  values(new.id,coalesce(nullif(regexp_replace(new.raw_user_meta_data->>'username','[^A-Za-z0-9_]','','g'),''),'user_'||substr(replace(new.id::text,'-',''),1,8)))
  on conflict do nothing;
  return new;
end
$function$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

create or replace function public.trade_block_check()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  if exists(select 1 from public.blocks where (blocker_id=new.proposer_id and blocked_id=new.recipient_id) or (blocker_id=new.recipient_id and blocked_id=new.proposer_id)) then raise exception 'cannot trade with this user'; end if;
  return new;
end
$function$;
revoke all on function public.trade_block_check() from public, anon, authenticated;

create or replace function public.capture_card_version()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  insert into public.card_versions(card_id,snapshot,changed_by,change_type) values(old.id,to_jsonb(old),auth.uid(),case when tg_op='DELETE' then 'delete' else 'update' end);
  if tg_op='DELETE' then return old; end if;
  return new;
end
$function$;
revoke all on function public.capture_card_version() from public, anon, authenticated;
