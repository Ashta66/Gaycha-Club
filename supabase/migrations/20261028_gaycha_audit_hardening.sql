-- Gaycha Club: hardening des suites de l'audit du 28/10/2026.
-- À appliquer d'abord sur une base de test. Migration additive, sans suppression de comptes/cartes/collections.

-- 1) Confidentialité par défaut : les profils ne sont publics qu'après opt-in.
ALTER TABLE public.user_preferences
  ALTER COLUMN profile_visible SET DEFAULT false;

-- Les anciennes lignes ont été créées avec une valeur par défaut publique.
-- Passage en privé par défaut pour éviter de traiter une valeur héritée comme un consentement explicite.
UPDATE public.user_preferences
SET profile_visible = false, updated_at = now()
WHERE profile_visible = true;

CREATE OR REPLACE FUNCTION public.is_profile_public(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(
    (SELECT up.profile_visible
     FROM public.user_preferences AS up
     WHERE up.user_id = p_user_id),
    false
  );
$$;
REVOKE ALL ON FUNCTION public.is_profile_public(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_profile_public(uuid) TO anon, authenticated;

DROP POLICY IF EXISTS profiles_public_visible ON public.profiles;
CREATE POLICY profiles_public_visible ON public.profiles
  FOR SELECT TO anon, authenticated
  USING (public.is_profile_public(id));

-- Afficher le pseudo uniquement dans un contexte relationnel déjà partagé
-- (conversation, échange, blocage ou annonce active), même si le profil est privé.
DROP POLICY IF EXISTS profiles_shared_context ON public.profiles;
CREATE POLICY profiles_shared_context ON public.profiles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE (c.user_a = (SELECT auth.uid()) AND c.user_b = profiles.id)
         OR (c.user_b = (SELECT auth.uid()) AND c.user_a = profiles.id)
    )
    OR EXISTS (
      SELECT 1 FROM public.trade_offers t
      WHERE (t.proposer_id = (SELECT auth.uid()) AND t.recipient_id = profiles.id)
         OR (t.recipient_id = (SELECT auth.uid()) AND t.proposer_id = profiles.id)
    )
    OR EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE b.blocker_id = (SELECT auth.uid()) AND b.blocked_id = profiles.id
    )
    OR EXISTS (
      SELECT 1 FROM public.market_listings l
      WHERE l.seller_id = profiles.id AND l.status = 'active'
    )
  );

-- 2) RLS explicite pour les tables d'échanges qui sont utilisées par des vues.
DROP POLICY IF EXISTS trade_offers_participant_read ON public.trade_offers;
CREATE POLICY trade_offers_participant_read ON public.trade_offers
  FOR SELECT TO authenticated
  USING (
    proposer_id = (SELECT auth.uid())
    OR recipient_id = (SELECT auth.uid())
  );

DROP POLICY IF EXISTS trade_items_participant_read ON public.trade_items;
CREATE POLICY trade_items_participant_read ON public.trade_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.trade_offers o
      WHERE o.id = trade_items.offer_id
        AND (o.proposer_id = (SELECT auth.uid()) OR o.recipient_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS market_listings_public_active ON public.market_listings;
CREATE POLICY market_listings_public_active ON public.market_listings
  FOR SELECT TO anon, authenticated
  USING (status = 'active');

DROP POLICY IF EXISTS card_instances_market_visible ON public.card_instances;
CREATE POLICY card_instances_market_visible ON public.card_instances
  FOR SELECT TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.market_listings l
      WHERE l.instance_id = card_instances.id AND l.status = 'active'
    )
  );

-- Les vues publiques et relationnelles s'exécutent avec les droits de l'appelant,
-- puis s'appuient sur les politiques ci-dessus et les politiques RLS déjà existantes.
CREATE OR REPLACE VIEW public.public_profiles
WITH (security_invoker = true)
AS
SELECT p.id, p.username, p.bio, p.xp, p.created_at
FROM public.profiles p
WHERE public.is_profile_public(p.id);

-- Le classement expose uniquement des agrégats des profils explicitement publics.
-- Le calcul agrégé reste dans une fonction étroitement limitée, plutôt que de donner
-- à chaque visiteur un accès en lecture aux collections complètes des autres joueurs.
CREATE OR REPLACE FUNCTION public.public_leaderboard()
RETURNS TABLE(username text, xp bigint, cards_found bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $
  SELECT p.username,
         p.xp,
         COUNT(DISTINCT ci.card_id)::bigint AS cards_found
  FROM public.profiles p
  LEFT JOIN public.card_instances ci ON ci.owner_id = p.id
  WHERE NOT p.is_suspended
    AND public.is_profile_public(p.id)
  GROUP BY p.id, p.username, p.xp
  ORDER BY p.xp DESC, COUNT(DISTINCT ci.card_id) DESC
  LIMIT 50;
$;
REVOKE ALL ON FUNCTION public.public_leaderboard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.public_leaderboard() TO anon, authenticated;

CREATE OR REPLACE VIEW public.leaderboard
WITH (security_invoker = true)
AS SELECT username, xp, cards_found FROM public.public_leaderboard();

ALTER VIEW public.market_view SET (security_invoker = true);
ALTER VIEW public.conversations_view SET (security_invoker = true);
ALTER VIEW public.trades_view SET (security_invoker = true);
ALTER VIEW public.trade_items_view SET (security_invoker = true);
ALTER VIEW public.blocked_view SET (security_invoker = true);

-- 3) Les tables internes aux défis secrets ne sont accessibles que par leurs fonctions SQL contrôlées.
REVOKE ALL ON TABLE public.secret_attempts FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.secret_challenges FROM PUBLIC, anon, authenticated;

-- La fonction de capture des versions est un trigger, pas une API RPC publique.
REVOKE ALL ON FUNCTION public.capture_card_version() FROM PUBLIC, anon, authenticated;

-- 4) Cohérence des cartes secrètes et transparence des probabilités.
-- Les cartes de rareté "secrete" publiées doivent aussi être protégées par is_secret.
UPDATE public.cards
SET is_secret = true
WHERE status = 'publie'::public.publish_status
  AND rarity = 'secrete'::public.rarity
  AND is_secret = false;

-- Aucune carte secrète n'est actuellement configurée comme obtenable via booster.
-- Déplacer le poids secret vers légendaire conserve la somme totale des probabilités.
UPDATE public.booster_types
SET odds = jsonb_set(
  jsonb_set(
    odds,
    '{secrete}',
    to_jsonb(0::numeric),
    true
  ),
  '{legendaire}',
  to_jsonb(COALESCE((odds->>'legendaire')::numeric, 0)
          + COALESCE((odds->>'secrete')::numeric, 0)),
  true
)
WHERE COALESCE((odds->>'secrete')::numeric, 0) > 0;

-- 5) Bucket avatars attendu par l'interface. Le bucket est public pour l'affichage
-- des URL d'avatar ; seules les personnes connectées peuvent écrire dans leur dossier.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE
SET public = true,
    file_size_limit = 2097152,
    allowed_mime_types = ARRAY['image/jpeg','image/png','image/webp'];

DROP POLICY IF EXISTS avatars_insert_own ON storage.objects;
CREATE POLICY avatars_insert_own ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS avatars_update_own ON storage.objects;
CREATE POLICY avatars_update_own ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS avatars_delete_own ON storage.objects;
CREATE POLICY avatars_delete_own ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

-- 6) Réécriture sécurisée de la fonction d'enregistrement du catalogue.
CREATE OR REPLACE FUNCTION public.admin_upsert_card(p_id uuid, p_data jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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
        AND s.name IN (
          'Bars gays & LGBTQ+ · France & Espagne',
          'Discothèques gays & LGBTQ+ · France & Espagne',
          'Saunas gays · France & Espagne'
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
$function$;
REVOKE ALL ON FUNCTION public.admin_upsert_card(uuid,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_upsert_card(uuid,jsonb) TO authenticated;
