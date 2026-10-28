-- Batch 5: current-source audit for Paris, Madrid and Montpellier; conflicting Valencia record explicitly flagged.
UPDATE public.cards
SET spec='Calle del Norte 15, 28015 Madrid · Horaires à confirmer sur le site officiel'
WHERE id=(SELECT id FROM public.cards WHERE name='Sauna Paraíso');
UPDATE public.venue_sources
SET official_url='https://saunaparaiso.com/',
    description_source_url='https://saunaparaiso.com/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif, adresse Calle del Norte 15, 28015 Madrid ; la page présente installations, horaires et tarifs. Carte maintenue en brouillon ; aucun visuel externe ajouté.')
WHERE card_id='da154a0e-6629-47cd-954d-8aeb4c43a340';

UPDATE public.cards
SET spec='1 rue de la Victoire de la Marne, 34000 Montpellier · Site officiel : one-sauna.com'
WHERE id=(SELECT id FROM public.cards WHERE name='ONE Sauna');
UPDATE public.venue_sources
SET official_url='https://www.one-sauna.com/',
    description_source_url='https://www.one-sauna.com/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif ; établissement annoncé ouvert 7 jours sur 7 au 1 rue de la Victoire de la Marne, Montpellier. Carte maintenue en brouillon ; droits visuels à vérifier si une image est ajoutée.')
WHERE card_id='3ee49323-7603-4978-819d-de08dd4ebbd0';

UPDATE public.cards
SET spec='5 rue Jules Latreilhe, 34000 Montpellier · Horaires à confirmer sur l’agenda local'
WHERE id=(SELECT id FROM public.cards WHERE name='Le Coxx');
UPDATE public.venue_sources
SET description_source_url='https://agendalgbt.com/en/montpellier/bars',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : Agenda LGBT mis à jour en octobre 2026 répertorie Le Coxx au 5 rue Jules Latreilhe et publie ses horaires. Carte maintenue en brouillon ; visuel et droits à vérifier.')
WHERE card_id='1e1bb692-3961-4841-b1d0-6b67fff1635f';

UPDATE public.cards
SET spec='5 rue Belmont, 34090 Montpellier · Horaires à confirmer sur l’agenda local'
WHERE id=(SELECT id FROM public.cards WHERE name='Madrediosa');
UPDATE public.venue_sources
SET description_source_url='https://agendalgbt.com/en/montpellier/bars',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : Agenda LGBT mis à jour en octobre 2026 référence Madrediosa comme bar queer au 5 rue Belmont. Carte maintenue en brouillon ; visuel et droits à vérifier.')
WHERE card_id='7e04e7dd-e4dd-4b1a-9132-be370aa7f015';

UPDATE public.venue_sources
SET description_source_url='https://agendalgbt.com/montpellier',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : Agenda LGBT Montpellier mis à jour en octobre 2026 cite Koncept Sauna parmi les deux saunas gays de la ville. Confirmer l’adresse et les horaires auprès de l’établissement avant publication ; aucun visuel intégré.')
WHERE card_id='272f567a-5609-400b-aade-208fff27ff72';

UPDATE public.venue_sources
SET official_url='https://cox.fr/',
    description_source_url='https://cox.fr/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif, Le Cox annonce ses horaires et son adresse au 15 rue des Archives, Paris 4e. Carte maintenue en brouillon ; aucun visuel externe ajouté.')
WHERE card_id='813efcef-0a02-4586-8059-006ddbc3ab8d';

UPDATE public.venue_sources
SET official_url='https://gibusclub.fr/',
    description_source_url='https://gibusclub.fr/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif avec programmation et événements annoncés en octobre/novembre 2026. Carte maintenue en brouillon ; droits visuels à vérifier.')
WHERE card_id='e1f6a25f-1447-4350-8d59-6b108ecfe336';

UPDATE public.venue_sources
SET official_url='https://www.suncity-paris.fr/',
    description_source_url='https://www.suncity-paris.fr/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif, programmation, horaires et adresse au 62 boulevard de Sébastopol, Paris 3e. Carte maintenue en brouillon ; droits visuels à vérifier.')
WHERE card_id='5a10c3f9-b5e7-402f-af74-5b1fbc391f8c';

UPDATE public.venue_sources
SET description_source_url='https://agendalgbt.com/en/montpellier/bars',
    verification_status='à vérifier',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : les listes LGBTQ+ mises à jour en octobre 2026 ne confirment pas ce nom parmi les bars actuellement référencés. Ne pas publier avant confirmation directe de l’activité et du nom commercial.')
WHERE card_id IN (
  '806b370e-c8c6-4313-8f5d-8e9fccad6a04',
  '97633d16-8c7d-4eb4-8699-acabd07db0d6',
  '0ba9f7c1-8992-4111-a1c4-0ec9aad7fafa'
);

UPDATE public.venue_sources
SET description_source_url='https://themusevalencia.com/',
    verification_status='à vérifier',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : le site officiel présente le bar comme actif et donne l’adresse C/ de Ruaya, 48, mais un autre annuaire récent l’indique fermé. Contradiction non résolue : contacter l’établissement avant toute publication ; conserver en brouillon.')
WHERE card_id='53f7b751-cfa8-4001-bce8-4cbf18a69f2d';
