-- Batch 3: archive duplicate card variants without deleting their audit history.
UPDATE public.cards
SET status='archive'::public.publish_status
WHERE id IN (
  '7a9a9bf4-4f50-4759-8d86-288128dd4ec2', -- Le L Bar duplicates Le L-Bar
  '42c36c9a-492e-4caa-8695-3bb86dd85927', -- Sauna Équateur duplicates Sauna Equateur
  '9091e8a0-2f8c-472a-9d9b-a6dd0b0d4dad', -- Le Kitsch · Biarritz duplicates existing Le Kitsch
  'd35802ec-5d03-4c7f-9619-c4b08093ab76', -- DoubleSide Sauna Hammam duplicates Double Side, Lyon
  'b124979e-3905-4630-b8ef-f899ff894e8d'  -- Ultra Klubs duplicates L’Ultra Klub, Bordeaux
);
UPDATE public.venue_sources
SET verification_status='à vérifier',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : fiche archivée comme doublon probable. La fiche canonique conservée est Le L-Bar (Lyon), Sauna Equateur (Strasbourg), Le Kitsch (Biarritz), Double Side (Lyon) ou L’Ultra Klub (Bordeaux), selon le cas. Historique conservé ; ne pas republier cette variante.')
WHERE card_id IN (
  '7a9a9bf4-4f50-4759-8d86-288128dd4ec2',
  '42c36c9a-492e-4caa-8695-3bb86dd85927',
  '9091e8a0-2f8c-472a-9d9b-a6dd0b0d4dad',
  'd35802ec-5d03-4c7f-9619-c4b08093ab76',
  'b124979e-3905-4630-b8ef-f899ff894e8d'
);

-- Mark activity as corroborated where a current official or recent local source supports it.
UPDATE public.venue_sources
SET verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : activité corroborée par le site officiel ou une source locale récente. La fiche reste en brouillon ; les horaires/adresses doivent être relus et les droits des visuels restent à vérifier avant publication.')
WHERE card_id IN (
  '941dff9e-34e8-4e4c-8e10-6a5c6e35072c', -- Le Trou
  'e32d2d3e-ffcb-4b42-be3b-315d20698062', -- Queen Club
  'ba5a92fe-cf48-4140-93d6-d2e9e0001036', -- Double Side
  '4a22fad4-2022-4d87-b1fb-4cfd285a749c', -- Le Quinquina
  'ea3b2b02-c1c1-4e5f-bc45-b82f9173f478', -- L’Éclipse
  '8c3ee908-3bb0-424b-a354-6c5b2a6d11af', -- Limelight
  'a7e5a6ca-4b84-43c8-9fad-3ac42213fcfe'  -- Buster Bar
);
