-- Gaycha Club batch 20: add two currently referenced queer bars in Paris.
-- Draft-only metadata; no image assets or photo rights are included.
begin;

insert into public.cards (series_id, number, name, rarity, bio, spec, anecdote, is_fictional, rights_checked, status, is_secret)
select v.series_id, v.number, v.name, 'commun', v.bio, v.spec, v.anecdote, false, false, 'brouillon', false
from (values
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,53,'Speechless · Paris','Bar à cocktails queer, culturel et végétal, proposant une programmation LGBTQIA+ de spectacles, drag, karaoké et rencontres.','45 rue de Montreuil, 75011 Paris · Programmation annoncée du mardi au samedi ; vérifier les horaires du jour.','Le lieu accueille des événements queer et culturels tout au long de l’année.'),
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,54,'Cabaret des Merveilles · Paris','Bar à cocktails queer féministe et espace artistique dédié aux spectacles vivants, aux performances et à la créativité collective.','25 rue de l’Hirondelle, 75006 Paris · Vérifier les horaires et la programmation avant visite.','Un lieu LGBTQIA+ particulièrement tourné vers les scènes lesbiennes et trans.')
) as v(series_id,number,name,bio,spec,anecdote)
where not exists (select 1 from public.cards c where c.series_id=v.series_id and c.number=v.number and c.name=v.name);

insert into public.venue_sources (card_id, venue_type, city, country, official_url, description_source_url, image_source_url, image_license, verification_status, last_verified_at, notes)
select c.id, 'bar', 'Paris', 'France',
 case when c.name='Speechless · Paris' then 'https://linktr.ee/speechlessbar_paris' else null end,
 case when c.name='Speechless · Paris' then 'https://linktr.ee/speechlessbar_paris' else 'https://parisjetaime.com/restaurant/cabaret-des-merveilles-bar-paris-p4796' end,
 null,
 'Aucune licence de réutilisation établie ; demander une autorisation explicite ou utiliser une image sous licence vérifiable.',
 'vérifié', now(),
 'Lot 20 — activité référencée par une source du lieu ou l’Office de tourisme de Paris, contrôle du 28/10/2026. Carte en brouillon ; aucun visuel intégré et aucun droit photo présumé.'
from public.cards c
where c.name in ('Speechless · Paris','Cabaret des Merveilles · Paris')
and not exists (select 1 from public.venue_sources vs where vs.card_id=c.id);

commit;