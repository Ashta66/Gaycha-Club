-- Perpignan LGBTQ+ venue audit. No card is published by this migration.
-- Backstage activity is confirmed; its external photo remains unlicensed, so the card stays draft.
UPDATE public.venue_sources
SET verification_status = 'en attente de droits',
    last_verified_at = now(),
    notes = concat_ws(E'\n',
      nullif(notes, ''),
      'Audit du 28/10/2026 : activité du Backstage corroborée par QLIST (fiche mise à jour le 17/10/2026) et par le Centre LGBT+66, qui y a organisé un événement le 04/10/2026. Adresse indiquée : 1 rue Pierre Puiggary, Perpignan. Le lieu est confirmé comme bar LGBTQ+ actif ; photo externe conservée en prévisualisation uniquement tant que les droits de réutilisation ne sont pas confirmés.'
    )
WHERE card_id = 'd6768ef9-485f-42ec-a69e-86150140e006';

-- Add the officially documented Le Déstressium as a draft, with no image.
INSERT INTO public.cards (series_id, number, name, rarity, bio, spec, anecdote, image_path, is_fictional, rights_checked, status, is_secret)
SELECT s.id, 31, 'Le Déstressium · Perpignan', 'commun'::public.rarity,
  'Sauna et espace balnéo à Perpignan, avec des créneaux 100 % masculins et des plages toutes tendances selon le calendrier officiel.',
  '9 rue Joseph Cugnot, 66000 Perpignan · Site officiel : ledestressium.fr',
  'Les horaires et conditions varient selon les créneaux ; consulter le site officiel avant toute visite.',
  NULL, false, false, 'brouillon'::public.publish_status, false
FROM public.series s
WHERE s.name = 'Saunas gays · France & Espagne'
ON CONFLICT (series_id, number) DO NOTHING;

INSERT INTO public.venue_sources
  (card_id, venue_type, city, country, official_url, description_source_url, image_source_url, image_license, verification_status, last_verified_at, notes)
SELECT c.id, 'sauna', 'Perpignan', 'France',
  'https://ledestressium.fr/',
  'https://ledestressium.fr/contact/',
  NULL,
  'Aucune photo intégrée ; droits visuels à vérifier lors de l’ajout d’une image.',
  'vérifié',
  now(),
  'Audit du 28/10/2026 : établissement et adresse confirmés par le site officiel, notamment la page Contact (9 rue Joseph Cugnot, 66000 Perpignan). La fiche reste en brouillon et aucune photo n’est intégrée. Avant publication, ajouter un visuel libre de droits ou autorisé.'
FROM public.cards c
JOIN public.series s ON s.id = c.series_id
WHERE c.name = 'Le Déstressium · Perpignan'
  AND s.name = 'Saunas gays · France & Espagne'
ON CONFLICT (card_id) DO UPDATE SET
  venue_type = excluded.venue_type,
  city = excluded.city,
  country = excluded.country,
  official_url = excluded.official_url,
  description_source_url = excluded.description_source_url,
  verification_status = excluded.verification_status,
  last_verified_at = excluded.last_verified_at,
  notes = excluded.notes;

-- Editorial confirmation from the project administrator: retain Jet Set in the LGBTQ+ venue selection.
UPDATE public.venue_sources
SET verification_status='en attente de droits',
    last_verified_at=now(),
    notes=concat_ws(E'\\n',nullif(notes,''),'Confirmation de l’administrateur du projet le 28/10/2026 : conserver Jet Set dans la sélection des lieux LGBTQ+ de Perpignan. La carte reste en brouillon tant que les droits de réutilisation de la photo ne sont pas confirmés ; cette réserve concerne le visuel, pas la décision éditoriale de l’inclure.')
WHERE card_id='b32a605a-508f-4be6-b5fe-51ee39eaa7e9';
