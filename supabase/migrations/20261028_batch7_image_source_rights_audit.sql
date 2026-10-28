-- Batch 7: candidate visual sources for five additional venue cards.
-- Source links are not proof of reuse rights. No image_path is populated and no card is published.
-- Keep rights_checked=false until a written permission or a compatible per-image license is documented.

UPDATE public.venue_sources
SET image_source_url='https://www.dirtylemon.fr/',
    image_license='Autorisation requise — site officiel repéré ; aucune licence de réutilisation explicite documentée.',
    notes=concat_ws(E'\n',nullif(notes,''),'Audit visuel du 28/10/2026 : site officiel enregistré comme piste de contact/source. Ne pas copier une photo sans accord explicite ou licence de réutilisation clairement applicable.')
WHERE card_id='aeb825db-ab36-4d19-a325-ec2dfe5b6bab';

UPDATE public.venue_sources
SET image_source_url='https://www.h2o-saunapourlui.fr/',
    image_license='Autorisation requise — site officiel repéré ; aucune licence de réutilisation explicite documentée.',
    notes=concat_ws(E'\n',nullif(notes,''),'Audit visuel du 28/10/2026 : site officiel enregistré comme piste de contact/source. Demander l’autorisation d’utiliser une photo de l’établissement ; aucune image intégrée.')
WHERE card_id='813fb7f8-0c56-42d5-b0d7-b58ea31d935d';

UPDATE public.venue_sources
SET image_source_url='https://eclipse-toulouse.com/',
    image_license='Autorisation requise — site officiel repéré ; aucune licence de réutilisation explicite documentée.',
    notes=concat_ws(E'\n',nullif(notes,''),'Audit visuel du 28/10/2026 : site officiel enregistré comme piste de contact/source. Demander l’accord pour l’usage sur carte web ; ne pas présumer que les photos du site sont réutilisables.')
WHERE card_id='ea3b2b02-c1c1-4e5f-bc45-b82f9173f478';

UPDATE public.venue_sources
SET image_source_url='https://les-thermes-marseille.com/',
    image_license='Autorisation requise — site officiel repéré ; aucune licence de réutilisation explicite documentée.',
    notes=concat_ws(E'\n',nullif(notes,''),'Audit visuel du 28/10/2026 : site officiel enregistré comme piste de contact/source. Vérifier auprès du lieu que l’image proposée peut être réutilisée sur le site et les cartes.')
WHERE card_id='1abba1e7-0dd7-431d-ae0b-e369d02f77c2';

UPDATE public.venue_sources
SET image_source_url='https://www.limelight-toulouse.com/',
    image_license='Autorisation requise — site officiel repéré ; aucune licence de réutilisation explicite documentée.',
    notes=concat_ws(E'\n',nullif(notes,''),'Audit visuel du 28/10/2026 : site officiel enregistré comme piste de contact/source. Demander une autorisation ou choisir une image sous licence vérifiable avant intégration.')
WHERE card_id='8c3ee908-3bb0-424b-a354-6c5b2a6d11af';

-- Deliberately leave cards.image_path unchanged and rights_checked=false.