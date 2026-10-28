-- Allow catalog managers to create and edit series and configure existing boosters.
-- Card management already accepts admin/catalog_manager; keep booster changes behind a validated SECURITY DEFINER RPC.

DROP POLICY IF EXISTS series_catalog_manager_write ON public.series;
CREATE POLICY series_catalog_manager_write
ON public.series
FOR ALL
TO authenticated
USING (public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]))
WITH CHECK (public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]));

CREATE OR REPLACE FUNCTION public.admin_set_booster(
  p_slug text,
  p_odds jsonb,
  p_price bigint,
  p_pity integer,
  p_cooldown integer,
  p_active boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  old public.booster_types;
  total numeric := 0;
  k text;
BEGIN
  IF u IS NULL OR NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_odds IS NULL OR jsonb_typeof(p_odds) <> 'object' THEN
    RAISE EXCEPTION 'odds must be a JSON object';
  END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(p_odds)) <> 6 THEN
    RAISE EXCEPTION 'odds must contain exactly the six rarity keys';
  END IF;

  SELECT * INTO old FROM public.booster_types WHERE slug = p_slug FOR UPDATE;
  IF old.id IS NULL THEN RAISE EXCEPTION 'unknown booster'; END IF;

  FOREACH k IN ARRAY ARRAY['commun','peu_commun','rare','epique','legendaire','secrete'] LOOP
    IF NOT (p_odds ? k) OR jsonb_typeof(p_odds->k) <> 'number' THEN
      RAISE EXCEPTION 'missing or non-numeric odds for %', k;
    END IF;
    IF (p_odds->>k)::numeric < 0 THEN RAISE EXCEPTION 'negative odds for %', k; END IF;
    total := total + (p_odds->>k)::numeric;
  END LOOP;

  IF abs(total - 100) > 0.001 THEN RAISE EXCEPTION 'odds must sum to 100 (got %)', total; END IF;
  IF p_price IS NULL OR p_price < 0 OR p_pity IS NULL OR p_pity < 1
     OR p_cooldown IS NULL OR p_cooldown < 0 OR p_active IS NULL THEN
    RAISE EXCEPTION 'invalid booster settings';
  END IF;

  UPDATE public.booster_types
     SET odds = p_odds, price = p_price, pity_threshold = p_pity,
         cooldown_hours = p_cooldown, active = p_active
   WHERE slug = p_slug;

  PERFORM public.log_audit(
    'booster.update',
    jsonb_build_object('slug', p_slug, 'old', to_jsonb(old),
      'new', jsonb_build_object('odds', p_odds, 'price', p_price, 'pity', p_pity,
                                'cooldown', p_cooldown, 'active', p_active))
  );
END
$function$;

REVOKE ALL ON FUNCTION public.admin_set_booster(text,jsonb,bigint,integer,integer,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_set_booster(text,jsonb,bigint,integer,integer,boolean) TO authenticated, service_role;
