-- Batch 8: refresh current venue verification for three LGBTQ+ venues.
-- Sources were checked on 2026-10-28. This does not publish cards or grant image rights.

update public.venue_sources
set official_url = 'https://www.letrashbar.com/',
    description_source_url = 'https://agendalgbt.com/marseille/cruising',
    verification_status = 'vérifié',
    last_verified_at = now(),
    image_source_url = coalesce(image_source_url, 'https://www.letrashbar.com/'),
    image_license = 'Aucune licence de réutilisation vérifiée. Site officiel noté comme piste de contact uniquement ; ne pas intégrer de photo sans autorisation ou licence compatible.',
    notes = concat_ws(E'\n',
      nullif(notes, ''),
      'Audit du 28/10/2026 : adresse concordante 28 rue du Berceau, 13005 Marseille, confirmée par Agenda LGBT (mise à jour octobre 2026), Le6 et plusieurs annuaires récents. L’adresse divergente « 20 rue Sainte » trouvée sur La Famille LGBT semble être une fiche erronée. Carte maintenue en brouillon ; aucune photo n’est autorisée par cette vérification.')
where card_id = 'de79b5b7-4db9-4ab2-99c9-f961595b1302';

update public.cards
set spec = '28 rue du Berceau, 13005 Marseille · Bar gay/cruising · Horaires à confirmer avant visite'
where id = 'de79b5b7-4db9-4ab2-99c9-f961595b1302'
  and status = 'brouillon';

update public.venue_sources
set official_url = 'https://saunaoctopus.com/',
    description_source_url = 'https://www.patroc.com/gay/madrid/gayguide.html',
    verification_status = 'vérifié',
    last_verified_at = now(),
    image_source_url = coalesce(image_source_url, 'https://saunaoctopus.com/'),
    image_license = 'Site officiel repéré ; aucune licence de réutilisation explicite documentée. Autorisation requise avant intégration de photos.',
    notes = concat_ws(E'\n',
      nullif(notes, ''),
      'Audit du 28/10/2026 : établissement actif corroboré par le guide gay Patroc 2026 et WhereIs.Gay. Adresse confirmée : C. de Churruca 10, Madrid 28004. Carte conservée en brouillon ; aucune photo réutilisée et droits visuels non validés.')
where card_id = '67c3df7c-2a6a-4019-ba0b-c78a7d40eded';

update public.cards
set spec = 'Calle de Churruca 10, 28004 Madrid · Sauna gay avec piscine chauffée et espaces détente · Horaires à confirmer sur le site officiel'
where id = '67c3df7c-2a6a-4019-ba0b-c78a7d40eded'
  and status = 'brouillon';

update public.venue_sources
set description_source_url = 'https://themusevalencia.com/eventos-valencia/',
    verification_status = 'vérifié',
    last_verified_at = now(),
    image_source_url = coalesce(image_source_url, 'https://themusevalencia.com/'),
    image_license = 'Site officiel repéré ; aucune licence de réutilisation explicite documentée. Autorisation requise avant intégration de photos.',
    notes = concat_ws(E'\n',
      nullif(notes, ''),
      'Audit du 28/10/2026 : l’activité est corroborée par le site officiel et sa page événements, qui annonce des soirées les vendredis et samedis à C/ de Ruaya 48, València. Une source secondaire signalait une possible fermeture ; la source officielle actuelle prévaut pour l’existence du lieu, sans garantir les horaires de chaque semaine. Carte conservée en brouillon jusqu’au contrôle final de l’adresse et des droits photo.')
where card_id = '53f7b751-cfa8-4001-bce8-4cbf18a69f2d';

update public.cards
set spec = 'C/ de Ruaya, 48, 46009 València · Pub/club LGTBIQ+ avec DJs et shows drag · Vérifier la programmation avant visite'
where id = '53f7b751-cfa8-4001-bce8-4cbf18a69f2d'
  and status = 'brouillon';
