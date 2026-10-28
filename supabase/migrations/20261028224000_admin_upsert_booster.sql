CREATE OR REPLACE FUNCTION public.admin_upsert_booster(
  p_slug text,
  p_name text,
  p_cards_per_pack integer,
  p_odds jsonb,
  p_price bigint,
  p_pity integer,
  p_cooldown integer,
  p_active boolean
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  old public.booster_types;
  total numeric := 0;
  k text;
  result_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_slug IS NULL OR p_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' OR char_length(p_slug) > 80 THEN
    RAISE EXCEPTION 'invalid booster slug';
  END IF;
  IF p_name IS NULL OR char_length(btrim(p_name)) < 2 OR char_length(btrim(p_name)) > 100 THEN
    RAISE EXCEPTION 'invalid booster name';
  END IF;
  IF p_cards_per_pack IS NULL OR p_cards_per_pack < 1 OR p_cards_per_pack > 50 THEN
    RAISE EXCEPTION 'cards per pack must be between 1 and 50';
  END IF;
  IF p_odds IS NULL OR jsonb_typeof(p_odds) <> 'object' OR (SELECT count(*) FROM jsonb_object_keys(p_odds)) <> 6 THEN
    RAISE EXCEPTION 'odds must contain exactly the six rarity keys';
  END IF;
  FOREACH k IN ARRAY ARRAY['commun','peu_commun','rare','epique','legendaire','secrete'] LOOP
    IF NOT (p_odds ? k) OR jsonb_typeof(p_odds->k) <> 'number' THEN
      RAISE EXCEPTION 'missing or non-numeric odds for %', k;
    END IF;
    IF (p_odds->>k)::numeric < 0 THEN RAISE EXCEPTION 'negative odds for %', k; END IF;
    total := total + (p_odds->>k)::numeric;
  END LOOP;
  IF abs(total - 100) > 0.001 THEN RAISE EXCEPTION 'odds must sum to 100 (got %)', total; END IF;
  IF p_price IS NULL OR p_price < 0 OR p_pity IS NULL OR p_pity < 1 OR p_cooldown IS NULL OR p_cooldown < 0 OR p_active IS NULL THEN
    RAISE EXCEPTION 'invalid booster settings';
  END IF;

  SELECT * INTO old FROM public.booster_types WHERE slug = p_slug FOR UPDATE;
  IF old.id IS NULL THEN
    INSERT INTO public.booster_types(slug,name,cards_per_pack,odds,price,pity_threshold,cooldown_hours,active)
    VALUES(p_slug,btrim(p_name),p_cards_per_pack,p_odds,p_price,p_pity,p_cooldown,p_active)
    RETURNING id INTO result_id;
  ELSE
    UPDATE public.booster_types
       SET name=btrim(p_name), cards_per_pack=p_cards_per_pack, odds=p_odds, price=p_price,
           pity_threshold=p_pity, cooldown_hours=p_cooldown, active=p_active
     WHERE id=old.id RETURNING id INTO result_id;
  END IF;
  PERFORM public.log_audit(
    CASE WHEN old.id IS NULL THEN 'booster.create' ELSE 'booster.update' END,
    jsonb_build_object('slug',p_slug,'old',to_jsonb(old),'new',jsonb_build_object(
      'name',btrim(p_name),'cards_per_pack',p_cards_per_pack,'odds',p_odds,'price',p_price,
      'pity',p_pity,'cooldown',p_cooldown,'active',p_active))
  );
  RETURN result_id;
END
$function$;
REVOKE ALL ON FUNCTION public.admin_upsert_booster(text,text,integer,jsonb,bigint,integer,integer,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_upsert_booster(text,text,integer,jsonb,bigint,integer,integer,boolean) TO authenticated, service_role;
