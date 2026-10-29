-- Serialize attempts for the same user/challenge pair.
-- This prevents concurrent requests from bypassing the hourly limit or
-- racing to award the same secret reward more than once.
CREATE OR REPLACE FUNCTION public.attempt_secret_challenge(p_slug text, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  u uuid := auth.uid();
  ch public.secret_challenges;
  normalized text;
  ok boolean := false;
  card_row public.cards;
begin
  if u is null then raise exception 'auth required'; end if;
  if length(coalesce(p_slug,'')) > 80 or length(coalesce(p_answer,'')) > 120 then
    raise exception 'invalid input';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id=u and p.age_confirmed_at is not null and not p.is_suspended
  ) then
    raise exception 'forbidden';
  end if;

  select * into ch from public.secret_challenges where slug=p_slug and active;
  if ch.id is null then raise exception 'unknown challenge'; end if;

  -- A transaction-level lock is released automatically on success or error.
  -- The lock is scoped to this authenticated user and this challenge only.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(u::text || ':' || ch.id::text, 0)
  );

  -- Recheck after acquiring the lock: another request may have solved it.
  if exists (
    select 1 from public.secret_discoveries d
    where d.user_id=u and d.challenge_id=ch.id
  ) then
    return jsonb_build_object('ok',true,'already',true,'message','Secret déjà découvert.');
  end if;

  if (
    select count(*) from public.secret_attempts a
    where a.user_id=u and a.challenge_id=ch.id
      and a.attempted_at > now()-interval '1 hour'
  ) >= 8 then
    raise exception 'too many attempts; try again later';
  end if;

  normalized := regexp_replace(lower(btrim(coalesce(p_answer,''))), '[^a-z0-9]', '', 'g');
  ok := encode(extensions.digest(normalized, 'sha256'), 'hex') = ch.answer_digest;

  insert into public.secret_attempts(user_id,challenge_id,correct)
  values(u,ch.id,ok);

  if not ok then
    return jsonb_build_object('ok',false,'message','Ce n’est pas encore ça. Relis l’indice et retente ta chance.');
  end if;

  insert into public.secret_discoveries(user_id,challenge_id,reward_card_id)
  values(u,ch.id,ch.reward_card_id)
  on conflict(user_id,challenge_id) do nothing;

  select * into card_row from public.cards where id=ch.reward_card_id;
  if card_row.id is not null and not exists (
    select 1 from public.card_instances i
    where i.owner_id=u and i.card_id=card_row.id
  ) then
    insert into public.card_instances(card_id,owner_id)
    values(card_row.id,u);
  end if;

  return jsonb_build_object(
    'ok',true,'already',false,
    'message','Secret découvert ! Une nouvelle carte rejoint ta collection.',
    'card_id',ch.reward_card_id
  );
end
$function$;
