-- Batch 10: refresh current activity/address sources for four venues.
-- Photo rights remain unconfirmed. All cards remain drafts.

update public.venue_sources
set official_url='https://queenclub.fr/',
    description_source_url='https://queenclub.fr/',
    image_source_url='https://queenclub.fr/',
    image_license='Site officiel avec visuels promotionnels ; licence de réutilisation non documentée. Demander une autorisation avant intégration.',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : site officiel actif confirme le Queen Club, club LGBT+ au 3 rue Terme, 69001 Lyon. Horaires affichés jeudi–dimanche, 23h–5h/6h selon la page ; vérifier la programmation de la soirée. Aucun droit de réutilisation des photos n’est établi.')
where card_id='e32d2d3e-ffcb-4b42-be3b-315d20698062';

update public.cards
set spec='3 rue Terme, 69001 Lyon · Club LGBT+ avec DJs et shows drag · Jeudi–dimanche à partir de 23h ; horaires de fermeture à confirmer selon la soirée'
where id='e32d2d3e-ffcb-4b42-be3b-315d20698062' and status='brouillon';

update public.venue_sources
set official_url='https://www.visiterlyon.com/decouvrir/lyon-comme-vous-laimez/lyon-ville-lgbtq/nos-adresses-festives-lgbtq-coups-de-coeur2',
    description_source_url='https://l-essenciel.fr/lieu/3-l-bar',
    image_source_url='https://l-essenciel.fr/lieu/3-l-bar',
    image_license='Sources touristiques et guide spécialisé avec visuels éventuels ; aucune licence de réutilisation établie. Demander une autorisation avant intégration.',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : le bar lesbien/queer est référencé par l’Office de tourisme de Lyon et le guide Essenciel. Adresse retenue : 19 rue du Garet, 69001 Lyon (attention : certaines fiches secondaires indiquent à tort rue du Chariot d’Or). Les horaires varient selon les sources ; à confirmer. Aucune photo réutilisée.')
where card_id='e48878c5-23dc-4b83-b21f-ac353ba75ccc';

update public.cards
set spec='19 rue du Garet, 69001 Lyon · Bar lesbien et queer, cocktails et cuisine maison · Horaires à confirmer auprès de l’établissement'
where id='e48878c5-23dc-4b83-b21f-ac353ba75ccc' and status='brouillon';

update public.venue_sources
set official_url='https://www.tourisme64.com/sur-place/activites/biarritz/LOIAQU064FS0002K-le-caveau/',
    description_source_url='https://www.tourisme64.com/sur-place/activites/biarritz/LOIAQU064FS0002K-le-caveau/',
    image_source_url='https://www.tourisme64.com/sur-place/activites/biarritz/LOIAQU064FS0002K-le-caveau/',
    image_license='Office de tourisme source ; droits des photos non établis. Ne pas réutiliser les images sans licence ou autorisation explicite.',
    verification_status='vérifié',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : l’Office de tourisme du Pays basque annonce Le Caveau ouvert en 2026 tous les soirs de minuit à 6h, au 4 rue Gambetta, 64200 Biarritz. La fiche tourisme confirme une discothèque généraliste à ambiance mixte ; garder la qualification LGBTQ+ prudente et ne pas présenter le lieu comme exclusivement gay sans autre preuve. Droits photo non validés.')
where card_id='9af8da5a-cb38-4860-91bf-1b1ff10a4db2';

update public.cards
set spec='4 rue Gambetta, 64200 Biarritz · Discothèque festive et mixte, fréquentée par plusieurs générations · Ouverture annoncée tous les soirs, 00h–06h'
where id='9af8da5a-cb38-4860-91bf-1b1ff10a4db2' and status='brouillon';

update public.venue_sources
set official_url='https://linktr.ee/LeCoxxMontpellier',
    description_source_url='https://www.fiertemontpellierpride.com/le-coxx/',
    image_source_url='https://www.fiertemontpellierpride.com/le-coxx/',
    image_license='Page associative avec visuels éventuels ; licence de réutilisation non documentée. Demander l’autorisation avant intégration.',
    verification_status='à vérifier',
    last_verified_at=now(),
    notes=concat_ws(E'\n',nullif(notes,''),'Audit du 28/10/2026 : adresse confirmée au 5 rue Jules Latreilhe, 34000 Montpellier par Fierté Montpellier Pride et un annuaire professionnel. Une source récente (WhereIs.Gay, vérification Google Maps du 25/10/2026) indique une fermeture, tandis que d’autres annuaires affichent encore des horaires. Statut contradictoire : contacter l’établissement ou vérifier ses annonces sociales avant publication. Aucun droit photo établi.')
where card_id='1e1bb692-3961-4841-b1d0-6b67fff1635f';

update public.cards
set spec='5 rue Jules Latreilhe, 34000 Montpellier · Bar gay historique avec musique et soirées à thème · Statut d’ouverture contradictoire : vérifier avant visite'
where id='1e1bb692-3961-4841-b1d0-6b67fff1635f' and status='brouillon';
