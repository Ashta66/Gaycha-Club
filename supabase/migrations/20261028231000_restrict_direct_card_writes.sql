CREATE OR REPLACE FUNCTION public.admin_update_venue_card_metadata(
  p_card uuid,
  p_image_path text,
  p_rights_checked boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  old_card public.cards;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF p_card IS NULL OR p_rights_checked IS NULL THEN
    RAISE EXCEPTION 'invalid card metadata';
  END IF;
  SELECT * INTO old_card FROM public.cards WHERE id=p_card FOR UPDATE;
  IF old_card.id IS NULL THEN RAISE EXCEPTION 'unknown card'; END IF;

  IF NULLIF(BTRIM(COALESCE(p_image_path,'')),'') IS NOT NULL THEN
    IF NOT p_rights_checked THEN RAISE EXCEPTION 'image rights must be confirmed'; END IF;
    IF NOT old_card.is_fictional AND NOT EXISTS (
      SELECT 1 FROM public.venue_sources v
      WHERE v.card_id=p_card
        AND NULLIF(BTRIM(v.image_source_url),'') IS NOT NULL
        AND NULLIF(BTRIM(v.image_license),'') IS NOT NULL
        AND v.image_license NOT IN ('à vérifier','en attente de droits')
    ) THEN
      RAISE EXCEPTION 'verified image source and license metadata required';
    END IF;
  END IF;

  UPDATE public.cards
     SET image_path=NULLIF(BTRIM(COALESCE(p_image_path,'')),''),
         rights_checked=p_rights_checked
   WHERE id=p_card;

  PERFORM public.log_audit(
    'card.venue_image_metadata',
    jsonb_build_object('card',p_card,'old_image_path',old_card.image_path,
      'new_image_path',NULLIF(BTRIM(COALESCE(p_image_path,'')),''),
      'old_rights_checked',old_card.rights_checked,'new_rights_checked',p_rights_checked)
  );
END
$function$;

REVOKE ALL ON FUNCTION public.admin_update_venue_card_metadata(uuid,text,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_update_venue_card_metadata(uuid,text,boolean) TO authenticated, service_role;

DROP POLICY IF EXISTS cards_write ON public.cards;
REVOKE INSERT, UPDATE, DELETE ON public.cards FROM anon, authenticated;