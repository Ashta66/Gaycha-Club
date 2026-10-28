-- Batch 2: add six real LGBTQ+ venues across five cities.
-- All new cards are drafts with no image, no rights claim, and no automatic publication.
WITH new_cards AS (
  INSERT INTO public.cards
    (series_id, number, name, rarity, bio, spec, anecdote, image_path, is_fictional, rights_checked, status, is_secret)
  VALUES
    ('4e8c168b-1552-45ee-b362-cbd904b84b29',43,'Le Trou · Lyon','commun'::public.rarity,
     'Bar de cruising gay historique dans les pentes de la Croix-Rousse.',
     '6 rue Romarin, Lyon · Site : letrou.fr',
     'Vérifier les horaires et conditions d’accès sur le site officiel avant la visite.',
     NULL,false,false,'brouillon'::public.publish_status,false),
    ('4e8c168b-1552-45ee-b362-cbd904b84b29',44,'Le Trash Bar · Marseille','commun'::public.rarity,
     'Bar gay et lieu de cruising au cœur de la vie LGBTQ+ marseillaise.',
     'Marseille · Adresse et horaires à confirmer auprès de sources récentes.',
     'La fiche est à compléter avec l’adresse officielle et un visuel autorisé.',
     NULL,false,false,'brouillon'::public.publish_status,false),
    ('4e8c168b-1552-45ee-b362-cbd904b84b29',45,'Chez les jumeaux · Toulouse','commun'::public.rarity,
     'Bar cité parmi les adresses de la scène LGBTQ+ toulousaine.',
     'Toulouse · Adresse et horaires à confirmer avant publication.',
     'Consulter l’agenda LGBTQ+ local avant de se déplacer.',
     NULL,false,false,'brouillon'::public.publish_status,false),
    ('4e8c168b-1552-45ee-b362-cbd904b84b29',46,'Le Kitsch · Biarritz','commun'::public.rarity,
     'Bar LGBT+ mentionné parmi les adresses queer du Pays basque.',
     'Biarritz · Adresse et horaires à confirmer avant publication.',
     'Fiche à compléter avec une source officielle et un visuel dont les droits sont autorisés.',
     NULL,false,false,'brouillon'::public.publish_status,false),
    ('55749559-9946-4ffa-9581-9df6409f2e65',23,'Tata Mona · Lyon','commun'::public.rarity,
     'After-club queer de Lyon associé aux nuits électroniques du week-end.',
     '18 rue du Doyenné, Lyon · Programmation à vérifier avant visite.',
     'Les horaires sont susceptibles de varier selon la programmation.',
     NULL,false,false,'brouillon'::public.publish_status,false),
    ('2550dab6-c62b-476e-afff-d66a78292ecb',32,'Sauna Octopus · Madrid','commun'::public.rarity,
     'Sauna gay de Madrid présenté comme orienté vers la communauté bear.',
     'Madrid · Adresse et horaires à confirmer auprès de sources officielles.',
     'Ne pas publier avant confirmation de l’activité actuelle et de l’adresse.',
     NULL,false,false,'brouillon'::public.publish_status,false)
  ON CONFLICT (series_id, number) DO NOTHING
  RETURNING id, name
)
INSERT INTO public.venue_sources
  (card_id, venue_type, city, country, official_url, description_source_url, image_source_url, image_license, verification_status, last_verified_at, notes)
SELECT id,
  CASE
    WHEN name LIKE 'Le Trou%' OR name LIKE 'Le Trash Bar%' OR name LIKE 'Chez les jumeaux%' OR name LIKE 'Le Kitsch%' THEN 'bar'
    WHEN name LIKE 'Tata Mona%' THEN 'discotheque'
    ELSE 'sauna'
  END,
  CASE
    WHEN name LIKE 'Le Trou%' OR name LIKE 'Tata Mona%' THEN 'Lyon'
    WHEN name LIKE 'Le Trash Bar%' THEN 'Marseille'
    WHEN name LIKE 'Chez les jumeaux%' THEN 'Toulouse'
    WHEN name LIKE 'Le Kitsch%' THEN 'Biarritz'
    ELSE 'Madrid'
  END,
  CASE WHEN name LIKE 'Sauna Octopus%' THEN 'Espagne' ELSE 'France' END,
  CASE WHEN name LIKE 'Le Trou%' THEN 'https://letrou.fr/' ELSE NULL END,
  CASE
    WHEN name LIKE 'Le Trou%' THEN 'https://letrou.fr/'
    WHEN name LIKE 'Le Trash Bar%' THEN 'https://maps.lafamillelgbt.fr/lieux/'
    WHEN name LIKE 'Chez les jumeaux%' THEN 'https://agendalgbt.com/en/toulouse'
    WHEN name LIKE 'Le Kitsch%' THEN 'https://www.france.fr/fr/article/lgbt-france-hotels-bars-evenements/'
    WHEN name LIKE 'Tata Mona%' THEN 'https://l-essenciel.fr/article/57-lyon-en-2026-etat-des-lieux-complet-des-etablissements-lgbt-bars-clubs-saunas-et-lieux-d-accueil'
    ELSE 'https://afterora.com/fr/country/spain'
  END,
  NULL,
  'Aucune image intégrée. Droits visuels à vérifier avant tout ajout.',
  'à vérifier',
  NULL,
  CASE
    WHEN name LIKE 'Le Trou%' THEN 'Source officielle de l’établissement. Fiche ajoutée en brouillon ; vérifier les informations pratiques et les droits du futur visuel.'
    WHEN name LIKE 'Le Trash Bar%' THEN 'Source de repérage : annuaire communautaire La Famille LGBT. Confirmer l’activité actuelle, l’adresse et les horaires auprès de l’établissement avant publication.'
    WHEN name LIKE 'Chez les jumeaux%' THEN 'Source de repérage : Agenda LGBT Toulouse. Confirmer l’activité actuelle et l’adresse avant publication.'
    WHEN name LIKE 'Le Kitsch%' THEN 'Source de repérage : France.fr. Confirmer l’activité actuelle et l’adresse avant publication.'
    WHEN name LIKE 'Tata Mona%' THEN 'Source de repérage : inventaire LGBTQ+ lyonnais mis à jour en octobre 2026. Confirmer la programmation et les horaires avant publication.'
    ELSE 'Source de repérage : guide LGBTQ+ Espagne. Confirmer l’activité actuelle et l’adresse auprès d’une source officielle avant publication.'
  END
FROM new_cards
ON CONFLICT (card_id) DO NOTHING;

-- Keep earlier Barcelona cards at their prior rights-review status; Arena Xperience still needs current verification.
UPDATE public.venue_sources
SET verification_status='en attente de droits'
WHERE card_id IN (
  SELECT c.id FROM public.cards c
  WHERE c.name IN ('Boys Bar BCN','La Federica','Safari Disco Club','Sauna Bruc')
);
UPDATE public.venue_sources
SET verification_status='à vérifier'
WHERE card_id IN (SELECT c.id FROM public.cards c WHERE c.name='Arena Xperience');
