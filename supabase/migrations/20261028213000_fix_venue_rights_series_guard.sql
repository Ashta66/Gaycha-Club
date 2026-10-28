-- Keep real-venue rights checks stable when series display names change.
CREATE OR REPLACE FUNCTION public.admin_upsert_card(p_id uuid, p_data jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  cid uuid;
  st public.publish_status;
  fict boolean;
  rc boolean;
  secret_card boolean;
  card_rarity public.rarity;
  card_image text;
  venue_series boolean;
BEGIN
  IF NOT public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  st := COALESCE(p_data->>'status','brouillon')::public.publish_status;
  fict := COALESCE((p_data->>'is_fictional')::boolean,true);
  rc := COALESCE((p_data->>'rights_checked')::boolean,false);
  card_rarity := (p_data->>'rarity')::public.rarity;
  card_image := NULLIF(BTRIM(p_data->>'image_path'),'');
  secret_card := COALESCE((p_data->>'is_secret')::boolean,false)
                 OR card_rarity = 'secrete'::public.rarity;

  IF char_length(BTRIM(COALESCE(p_data->>'name',''))) < 2 THEN
    RAISE EXCEPTION 'name required';
  END IF;

  IF st = 'publie' AND NOT fict THEN
    IF NOT rc THEN
      RAISE EXCEPTION 'rights check required for non-fictional card';
    END IF;

    SELECT EXISTS (
      SELECT 1 FROM public.series s
      WHERE s.id = (p_data->>'series_id')::uuid
        AND s.slug IN (
          'bars-gays-france',
          'discotheques-lgbtq',
          'saunas-gays'
        )
    ) INTO venue_series;

    IF venue_series THEN
      IF card_image IS NULL THEN
        RAISE EXCEPTION 'venue image required before publication';
      END IF;
      IF NOT EXISTS (
        SELECT 1
        FROM public.venue_sources v
        WHERE v.card_id = p_id
          AND v.verification_status = 'vérifié'
          AND COALESCE(NULLIF(BTRIM(v.official_url),''), NULLIF(BTRIM(v.description_source_url),'')) IS NOT NULL
          AND NULLIF(BTRIM(v.image_source_url),'') IS NOT NULL
          AND NULLIF(BTRIM(v.image_license),'') IS NOT NULL
          AND v.image_license NOT IN ('à vérifier','en attente de droits')
      ) THEN
        RAISE EXCEPTION 'venue verification and image rights metadata required before publication';
      END IF;
    END IF;
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.cards(
      series_id,season_id,number,name,rarity,spec,anecdote,bio,image_path,
      status,is_fictional,rights_checked,is_secret
    )
    VALUES (
      (p_data->>'series_id')::uuid,
      (SELECT s.id FROM public.seasons s ORDER BY s.name LIMIT 1),
      (p_data->>'number')::int,
      BTRIM(p_data->>'name'),
      card_rarity,
      NULLIF(p_data->>'spec',''),
      NULLIF(p_data->>'anecdote',''),
      NULLIF(p_data->>'bio',''),
      card_image,
      st,fict,rc,secret_card
    )
    RETURNING id INTO cid;
  ELSE
    UPDATE public.cards
    SET series_id=(p_data->>'series_id')::uuid,
        number=(p_data->>'number')::int,
        name=BTRIM(p_data->>'name'),
        rarity=card_rarity,
        spec=NULLIF(p_data->>'spec',''),
        anecdote=NULLIF(p_data->>'anecdote',''),
        bio=NULLIF(p_data->>'bio',''),
        image_path=card_image,
        status=st,
        is_fictional=fict,
        rights_checked=rc,
        is_secret=secret_card
    WHERE id=p_id
    RETURNING id INTO cid;

    IF cid IS NULL THEN
      RAISE EXCEPTION 'unknown card';
    END IF;
  END IF;

  PERFORM public.log_audit(
    CASE WHEN p_id IS NULL THEN 'card.create' ELSE 'card.update' END,
    jsonb_build_object('card',cid,'data',p_data,'is_secret',secret_card)
  );
  RETURN cid;
END;
$function$
;