-- Save venue source metadata and card image/rights metadata atomically.
CREATE OR REPLACE FUNCTION public.admin_save_venue_metadata(
  p_card uuid,
  p_venue jsonb,
  p_image_path text,
  p_rights_checked boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  venue_type_value text;
  city_value text;
  country_value text;
  status_value text;
  image_source_value text;
  image_license_value text;
  field_name text;
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_card IS NULL OR p_venue IS NULL OR jsonb_typeof(p_venue) <> 'object'
     OR p_rights_checked IS NULL THEN
    RAISE EXCEPTION 'invalid venue metadata';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.cards c WHERE c.id = p_card AND NOT c.is_fictional
  ) THEN
    RAISE EXCEPTION 'unknown venue card';
  END IF;

  -- Required fields must be JSON strings; ->> alone would coerce numbers/objects.
  IF jsonb_typeof(p_venue->'venue_type') IS DISTINCT FROM 'string'
     OR jsonb_typeof(p_venue->'city') IS DISTINCT FROM 'string'
     OR jsonb_typeof(p_venue->'country') IS DISTINCT FROM 'string' THEN
    RAISE EXCEPTION 'venue type, city and country must be strings';
  END IF;

  -- Optional text fields may be strings, JSON null, or omitted, but not arrays/objects/numbers.
  FOREACH field_name IN ARRAY ARRAY[
    'official_url', 'description_source_url', 'image_source_url',
    'image_license', 'verification_status', 'notes'
  ] LOOP
    IF p_venue ? field_name
       AND jsonb_typeof(p_venue->field_name) NOT IN ('string', 'null') THEN
      RAISE EXCEPTION 'venue metadata field must be text: %', field_name;
    END IF;
  END LOOP;

  venue_type_value := NULLIF(BTRIM(p_venue->>'venue_type'), '');
  city_value := NULLIF(BTRIM(p_venue->>'city'), '');
  country_value := NULLIF(BTRIM(p_venue->>'country'), '');
  status_value := COALESCE(NULLIF(BTRIM(p_venue->>'verification_status'), ''), 'à vérifier');
  image_source_value := NULLIF(BTRIM(p_venue->>'image_source_url'), '');
  image_license_value := COALESCE(NULLIF(BTRIM(p_venue->>'image_license'), ''), 'à vérifier');

  IF venue_type_value IS NULL OR venue_type_value NOT IN ('bar','discotheque','sauna')
     OR city_value IS NULL OR country_value IS NULL
     OR status_value NOT IN ('à vérifier','vérifié','fermé','en attente de droits') THEN
    RAISE EXCEPTION 'invalid venue fields';
  END IF;

  IF NULLIF(BTRIM(COALESCE(p_image_path,'')), '') IS NOT NULL THEN
    IF NOT p_rights_checked
       OR image_source_value IS NULL
       OR lower(image_license_value) IN ('à vérifier','en attente de droits')
       OR lower(image_license_value) LIKE '%autorisation requise%'
       OR lower(image_license_value) LIKE '%non identifié%'
       OR lower(image_license_value) LIKE '%non validé%'
       OR lower(image_license_value) LIKE '%droits gérés%' THEN
      RAISE EXCEPTION 'verified image source and license required';
    END IF;
  END IF;

  INSERT INTO public.venue_sources(
    card_id, venue_type, city, country, official_url,
    description_source_url, image_source_url, image_license,
    verification_status, notes
  )
  VALUES (
    p_card, venue_type_value, city_value, country_value,
    NULLIF(BTRIM(p_venue->>'official_url'), ''),
    NULLIF(BTRIM(p_venue->>'description_source_url'), ''),
    image_source_value, image_license_value,
    status_value, NULLIF(BTRIM(p_venue->>'notes'), '')
  )
  ON CONFLICT (card_id) DO UPDATE SET
    venue_type = EXCLUDED.venue_type,
    city = EXCLUDED.city,
    country = EXCLUDED.country,
    official_url = EXCLUDED.official_url,
    description_source_url = EXCLUDED.description_source_url,
    image_source_url = EXCLUDED.image_source_url,
    image_license = EXCLUDED.image_license,
    verification_status = EXCLUDED.verification_status,
    notes = EXCLUDED.notes;

  PERFORM public.admin_update_venue_card_metadata(
    p_card, p_image_path, p_rights_checked
  );

  PERFORM public.log_audit(
    'venue.sources.save',
    jsonb_build_object(
      'card', p_card,
      'venue_type', venue_type_value,
      'city', city_value,
      'country', country_value,
      'verification_status', status_value
    )
  );
END
$function$;

REVOKE ALL ON FUNCTION public.admin_save_venue_metadata(uuid,jsonb,text,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_venue_metadata(uuid,jsonb,text,boolean) TO authenticated, service_role;
