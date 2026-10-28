-- Batch 9: correct official source metadata and current addresses for four venues.
-- The official sites are leads for image permission only. No images are embedded and no rights are cleared.

update public.venue_sources
set official_url = 'https://h2o-sauna.fr/',
    description_source_url = 'https://h2o-sauna.fr/contact/',
    image_source_url = 'https://h2o-sauna.fr/',
    image_license = 'Site officiel avec galerie de photos ; licence de réutilisation non identifiée. Demander une autorisation écrite avant téléchargement ou intégration.',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = concat_ws(E'\n', nullif(notes, ''),
      'Audit du 28/10/2026 : site officiel actuel h2o-sauna.fr confirme le sauna gay au 44 avenue Gambetta, 34500 Béziers, ainsi que les horaires et équipements. L’ancien domaine h2o-saunapourlui.fr n’est plus la source principale. Les photos de la galerie restent soumises à autorisation.')
where card_id = '813fb7f8-0c56-42d5-b0d7-b58ea31d935d';

update public.cards
set spec = '44 avenue Gambetta, 34500 Béziers · Sauna gay de 350 m² avec jacuzzi, hammam, cabines et bar · Lun–mer 12h–19h30, jeu–sam 12h–1h, dim 12h–23h'
where id = '813fb7f8-0c56-42d5-b0d7-b58ea31d935d' and status = 'brouillon';

update public.venue_sources
set official_url = 'https://www.safaridiscoclub.com/',
    description_source_url = 'https://www.safaridiscoclub.com/',
    image_source_url = 'https://www.safaridiscoclub.com/',
    image_license = 'Site officiel et visuels d’événements repérés ; aucune licence de réutilisation explicite. Ne pas copier les photos ou flyers sans autorisation.',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = concat_ws(E'\n', nullif(notes, ''),
      'Audit du 28/10/2026 : site officiel affiche une programmation actuelle de soirées LGBTQ+, dont POPair, YASS! et BANANAS, et confirme l’adresse Carrer de Tarragona 141, 08014 Barcelona. Les photos et affiches sont des contenus promotionnels protégés en l’absence de licence explicite ; demander l’autorisation.')
where card_id = '4fcd75c5-684d-484a-a191-acadfa80d4fa';

update public.cards
set spec = 'Carrer de Tarragona, 141, 08014 Barcelona · Discothèque à deux salles (pop/hits et house), soirées LGBTQ+ et événements à thème · Vérifier la programmation avant visite'
where id = '4fcd75c5-684d-484a-a191-acadfa80d4fa' and status = 'brouillon';

update public.venue_sources
set official_url = 'https://saunabruc.com/',
    description_source_url = 'https://saunabruc.com/contacto/',
    image_source_url = 'https://saunabruc.com/',
    image_license = 'Site officiel avec images des installations ; licence de réutilisation non identifiée. Autorisation écrite requise avant intégration.',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = concat_ws(E'\n', nullif(notes, ''),
      'Audit du 28/10/2026 : site officiel actif ; page contact confirme Pau Claris 87, Barcelona, téléphone 93 487 48 14. Les visuels du site sont répertoriés comme pistes de contact uniquement, sans droit de réutilisation établi.')
where card_id = '313a3a4a-fd46-4821-a6d0-2ba09b536533';

update public.cards
set spec = 'Pau Claris, 87, Barcelona · Sauna gay avec piscine d’hydromassage, jacuzzi, sauna vapeur et sauna sec · Horaires à vérifier sur le site officiel'
where id = '313a3a4a-fd46-4821-a6d0-2ba09b536533' and status = 'brouillon';

update public.venue_sources
set official_url = 'https://l.hommeobar.gay/',
    description_source_url = 'https://l.hommeobar.gay/',
    image_source_url = 'https://l.hommeobar.gay/',
    image_license = 'Site officiel avec photos du lieu ; licence de réutilisation non identifiée. Demander l’autorisation avant intégration.',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = concat_ws(E'\n', nullif(notes, ''),
      'Audit du 28/10/2026 : domaine officiel actif l.hommeobar.gay confirme bar gay et fétiche, adresse 36 avenue de Verdun, 64200 Biarritz et horaires réguliers mercredi–dimanche 22h–2h, avec horaires saisonniers en juillet–août. Les images restent soumises à autorisation.')
where card_id = 'c4dd1d17-42fb-4e03-bdea-d4a1547ed89b';

update public.cards
set spec = '36 avenue de Verdun, 64200 Biarritz · Bar gay et fétiche · Mer–dim 22h–2h ; horaires saisonniers élargis en juillet–août'
where id = 'c4dd1d17-42fb-4e03-bdea-d4a1547ed89b' and status = 'brouillon';
