-- Fix the output-column name collision in the legacy achievement sync RPC.
-- Keep the RPC signature and existing unlock records for backward compatibility.
CREATE OR REPLACE FUNCTION public.sync_user_achievements()
RETURNS TABLE (achievement_key text, unlocked_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_unique integer;
  v_instances integer;
  v_rarities integer;
  v_catalogue integer;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT count(DISTINCT ci.card_id), count(*), count(DISTINCT c.rarity::text)
    INTO v_unique, v_instances, v_rarities
  FROM public.card_instances ci
  JOIN public.cards c ON c.id = ci.card_id
  WHERE ci.owner_id = v_user AND c.status::text = 'publie';

  SELECT count(*) INTO v_catalogue
  FROM public.cards c
  WHERE c.status::text = 'publie';

  INSERT INTO public.user_achievements(user_id, achievement_key)
  SELECT v_user, x.key
  FROM (VALUES
    ('first_card', v_unique >= 1),
    ('collector_10', v_unique >= 10),
    ('rainbow_4', v_rarities >= 4),
    ('duplicates_5', v_instances - v_unique >= 5),
    ('completion', v_catalogue > 0 AND v_unique >= v_catalogue)
  ) AS x(key, achieved)
  WHERE x.achieved
  ON CONFLICT ON CONSTRAINT user_achievements_pkey DO NOTHING;

  RETURN QUERY
  SELECT ua.achievement_key, ua.unlocked_at
  FROM public.user_achievements ua
  WHERE ua.user_id = v_user
  ORDER BY ua.unlocked_at;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_user_achievements() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sync_user_achievements() TO authenticated;

-- Add useful read-only administration metrics. All values remain scoped to staff.
CREATE OR REPLACE FUNCTION public.admin_stats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.is_staff(ARRAY['admin','moderator','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN jsonb_build_object(
    'comptes', (SELECT count(*) FROM public.profiles),
    'comptes_suspendus', (SELECT count(*) FROM public.profiles WHERE is_suspended),
    'exemplaires_de_cartes', (SELECT count(*) FROM public.card_instances),
    'cartes_publiees', (SELECT count(*) FROM public.cards WHERE status = 'publie'),
    'annonces_actives', (SELECT count(*) FROM public.market_listings WHERE status = 'active'),
    'echanges_en_attente', (SELECT count(*) FROM public.trade_offers WHERE status = 'pending'),
    'signalements_ouverts', (SELECT count(*) FROM public.reports WHERE status = 'open'),
    'monnaie_en_circulation', (SELECT coalesce(sum(balance), 0) FROM public.profiles),
    'connexions_30_jours', (SELECT count(*) FROM auth.users WHERE last_sign_in_at >= now() - interval '30 days'),
    'ouvertures_boosters', (
      SELECT count(*) FROM public.ledger
      WHERE reason LIKE 'booster:%'
         OR reason LIKE 'booster_gift:%'
         OR reason LIKE 'booster_paid:%'
    ),
    'top_cartes', (
      SELECT coalesce(jsonb_agg(jsonb_build_object(
        'name', ranked.name,
        'rarity', ranked.rarity,
        'count', ranked.copy_count
      ) ORDER BY ranked.copy_count DESC, ranked.name), '[]'::jsonb)
      FROM (
        SELECT c.name, c.rarity::text AS rarity, count(*) AS copy_count
        FROM public.card_instances ci
        JOIN public.cards c ON c.id = ci.card_id
        WHERE c.status = 'publie'
        GROUP BY c.id, c.name, c.rarity
        ORDER BY count(*) DESC, c.name
        LIMIT 5
      ) ranked
    )
  );
END
$function$;
