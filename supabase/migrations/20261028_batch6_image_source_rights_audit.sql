-- Batch 6: image-source audit. These URLs identify candidate visual sources only.
-- No images are downloaded or integrated because the source pages do not explicitly grant reuse rights.
-- Keep rights_checked=false and cards in draft until explicit permission or a reusable license is documented.

UPDATE public.venue_sources
SET image_source_url='https://cox.fr/albums-photos/',
    image_license='Autorisation requise — galerie officielle consultée, aucune licence de réutilisation explicite identifiée.',
    notes=concat_ws(E'\n', nullif(notes,''), 'Audit visuel du 28/10/2026 : galerie officielle repérée (https://cox.fr/albums-photos/). Les photos de la galerie ne sont pas libres de droits par défaut. Ne pas intégrer sans autorisation écrite ou licence explicite.')
WHERE card_id='813efcef-0a02-4586-8059-006ddbc3ab8d';

UPDATE public.venue_sources
SET image_source_url='https://gibusclub.fr/photos-4',
    image_license='Autorisation requise — galerie officielle consultée, aucune licence de réutilisation explicite identifiée.',
    notes=concat_ws(E'\n', nullif(notes,''), 'Audit visuel du 28/10/2026 : galerie officielle des soirées repérée (https://gibusclub.fr/photos-4). Photos événementielles potentiellement soumises aux droits des photographes et des personnes représentées. Ne pas intégrer sans autorisation/licence explicite.')
WHERE card_id='e1f6a25f-1447-4350-8d59-6b108ecfe336';

UPDATE public.venue_sources
SET image_source_url='https://www.suncity-paris.fr/',
    image_license='Autorisation requise — site officiel consulté, aucune licence de réutilisation explicite identifiée.',
    notes=concat_ws(E'\n', nullif(notes,''), 'Audit visuel du 28/10/2026 : site officiel repéré comme piste de contact/source. Aucune autorisation de réutilisation déduite de la simple présence des images sur le site. Ne pas intégrer sans accord explicite.')
WHERE card_id='5a10c3f9-b5e7-402f-af74-5b1fbc391f8c';

UPDATE public.venue_sources
SET image_source_url='https://hommeobar.gay/',
    image_license='Autorisation requise — site officiel consulté, aucune licence de réutilisation explicite identifiée.',
    notes=concat_ws(E'\n', nullif(notes,''), 'Audit visuel du 28/10/2026 : site officiel repéré comme piste de contact/source. Demander au lieu l’autorisation d’utiliser une photo pour la carte et conserver la preuve de l’accord.')
WHERE card_id='c4dd1d17-42fb-4e03-bdea-d4a1547ed89b';

UPDATE public.venue_sources
SET image_source_url='https://www.instagram.com/boum.marseille/',
    image_license='Autorisation requise — compte officiel/social repéré, aucun droit de réutilisation établi.',
    notes=concat_ws(E'\n', nullif(notes,''), 'Audit visuel du 28/10/2026 : compte Instagram du lieu repéré comme piste de contact/source. Les photos publiées sur un réseau social ne sont pas réutilisables automatiquement. Demander un accord explicite avant toute intégration.')
WHERE card_id='f973d33e-d2f0-4dce-be03-bed26b709cd5';

-- Deliberately do not set cards.image_path or rights_checked=true.
