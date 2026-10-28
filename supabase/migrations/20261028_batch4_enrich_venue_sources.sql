-- Batch 4: enrich venue source metadata across Marseille, Toulouse and Biarritz.
-- Do not publish cards or infer image rights.
UPDATE public.venue_sources
SET description_source_url='https://agendalgbt.com/marseille',
    verification_status='à vérifier',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : Agenda LGBT référence encore le Trash Bar comme bar de cruising, rue du Berceau. Une autre fiche communautaire donne une adresse différente (20 rue Sainte) : conflit d’adresse à résoudre auprès de l’établissement avant publication. Carte maintenue en brouillon, aucune photo intégrée.')
WHERE card_id=(SELECT id FROM public.cards WHERE name='Le Trash Bar · Marseille');

UPDATE public.cards
SET spec='1 rue André-Mercadier, 31000 Toulouse · Horaires à revérifier avant visite'
WHERE id=(SELECT id FROM public.cards WHERE name='Chez les jumeaux · Toulouse');
UPDATE public.venue_sources
SET description_source_url='https://agendalgbt.com/guides/quartier-gay-de-toulouse-ou-sortir-et-bonnes-adresses-lgbt',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : guide Agenda LGBT mis à jour le 23/09/2026 confirme l’établissement au 1 rue André-Mercadier et le décrit comme bar gay ouvert en 2026. Fiche toujours en brouillon ; pas de photo intégrée, droits visuels à vérifier.')
WHERE card_id=(SELECT id FROM public.cards WHERE name='Chez les jumeaux · Toulouse');

UPDATE public.venue_sources
SET description_source_url='https://www.planomato.com/es/madrid/v/sauna-octopus',
    verification_status='à vérifier',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : une fiche de repérage récente donne Sauna Octopus, sauna masculin à thème bear, au C. de Churruca, 10, Madrid. Source non officielle : confirmer l’activité et l’adresse auprès de l’établissement avant publication. Aucune image intégrée.')
WHERE card_id=(SELECT id FROM public.cards WHERE name='Sauna Octopus · Madrid');

UPDATE public.venue_sources
SET description_source_url='https://www.france.fr/fr/article/lgbt-france-hotels-bars-evenements/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : France.fr répertorie Le Kitsch comme bar LGBT+ à Biarritz. Fiche canonique conservée ; horaires, adresse précise et visuel à valider avant publication.')
WHERE card_id='a1554822-4b13-4a94-bdcb-5353f7de252d';

UPDATE public.venue_sources
SET official_url='https://hommeobar.gay/',
    description_source_url='https://hommeobar.gay/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif, adresse indiquée au 36 avenue de Verdun, Biarritz ; horaires publiés du mercredi au dimanche hors saison estivale. Photo et droits de réutilisation à vérifier avant intégration.')
WHERE card_id='c4dd1d17-42fb-4e03-bdea-d4a1547ed89b';

UPDATE public.venue_sources
SET verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : France.fr référence Le Caveau comme club de nuit LGBTQ+ à Biarritz. Vérifier adresse, horaires et activité directement auprès de l’établissement avant publication.')
WHERE card_id='9af8da5a-cb38-4860-91bf-1b1ff10a4db2';

UPDATE public.venue_sources
SET description_source_url='https://www.marseille-tourisme.com/vivez-marseille-blog/le-blog-marseille-a-la-carte/guide-des-lieux-lgbtqia-et-gay-friendly-a-marseille/',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : l’Office de tourisme de Marseille répertorie ce lieu dans son guide LGBTQIA+ récent. Carte maintenue en brouillon ; confirmer les informations pratiques et les droits des visuels avant publication.')
WHERE card_id IN (
  'f973d33e-d2f0-4dce-be03-bed26b709cd5',
  'd3cbecd4-919c-4f33-bfd3-182547bf24d3',
  'bef98719-2c27-4a8a-835b-73eacd10d2d2'
);

UPDATE public.venue_sources
SET official_url='https://les-thermes-marseille.com/',
    description_source_url='https://agendalgbt.com/marseille',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : Agenda LGBT référence Les Thermes, rue Mazagran, comme sauna gay ; un site officiel est enregistré. Confirmer horaires et tarifs directement avant publication.')
WHERE card_id='1abba1e7-0dd7-431d-ae0b-e369d02f77c2';
