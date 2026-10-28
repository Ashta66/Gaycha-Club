CREATE OR REPLACE FUNCTION public.my_missions()
RETURNS TABLE(slug text, title text, kind text, reward bigint, xp_reward integer, goal integer, progress integer, claimed boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  m public.missions;
  pk text;
  since timestamptz;
  prog integer;
BEGIN
  IF u IS NULL THEN RAISE EXCEPTION 'auth required'; END IF;

  FOR m IN SELECT * FROM public.missions WHERE active ORDER BY kind, reward LOOP
    IF m.kind = 'daily' THEN
      pk := to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD');
      since := date_trunc('day', now() AT TIME ZONE 'utc') AT TIME ZONE 'utc';
    ELSE
      pk := to_char(now() AT TIME ZONE 'utc', 'IYYY-"W"IW');
      since := date_trunc('week', now() AT TIME ZONE 'utc') AT TIME ZONE 'utc';
    END IF;

    IF m.metric = 'boosters_opened' THEN
      SELECT count(*) INTO prog
      FROM public.ledger l
      WHERE l.user_id = u
        AND (l.reason LIKE 'booster:%'
          OR l.reason LIKE 'booster_gift:%'
          OR l.reason LIKE 'booster_paid:%')
        AND l.created_at >= since;
    ELSE
      prog := m.goal;
    END IF;

    slug := m.slug;
    title := m.title;
    kind := m.kind;
    reward := m.reward;
    xp_reward := m.xp_reward;
    goal := m.goal;
    progress := least(prog, m.goal);
    claimed := EXISTS (
      SELECT 1 FROM public.mission_claims mc
      WHERE mc.user_id = u AND mc.mission_id = m.id AND mc.period_key = pk
    );
    RETURN NEXT;
  END LOOP;
END
$function$;