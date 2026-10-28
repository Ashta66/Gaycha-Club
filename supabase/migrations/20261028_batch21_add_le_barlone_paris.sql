-- Gaycha Club batch 21: add Le Barlone as a draft, based on a current queer event calendar.
-- Venue status, exact regular hours and image rights still require direct confirmation.
begin;
insert into public.cards (series_id, number, name, rarity, bio, spec, anecdote, is_fictional, rights_checked, status, is_secret)
select '4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid, 55, 'Le Barlone · Paris', 'commun',
 'Bar queer parisien accueillant des rencontres et événements culturels LGBTQIA+, notamment des rendez-vous artistiques et communautaires.',
 '13 rue Bergère, 75009 Paris · Vérifier le calendrier événementiel avant visite.',
 'Un lieu de rencontre pour les communautés et collectifs queer.', false, false, 'brouillon', false
where not exists (select 1 from public.cards c where c.series_id='4e8c168b-1552-45ee-b362-cbd904b84b29' and c.number=55 and c.name='Le Barlone · Paris');

insert into public.venue_sources (card_id, venue_type, city, country, official_url, description_source_url, image_source_url, image_license, verification_status, last_verified_at, notes)
select c.id, 'bar', 'Paris', 'France', null, 'https://www.parisestunepose.fr/agenda', null,
 'Aucune licence de réutilisation établie ; demander une autorisation explicite ou utiliser une image sous licence vérifiable.',
 'vérifié', now(),
 'Lot 21 — programmation queer récurrente confirmée par l’agenda du collectif Paris Est Une Pose en octobre 2026. Fiche maintenue en brouillon ; vérifier les horaires et le statut de bar auprès du lieu. Aucun visuel intégré.'
from public.cards c
where c.name='Le Barlone · Paris' and c.series_id='4e8c168b-1552-45ee-b362-cbd904b84b29'
and not exists (select 1 from public.venue_sources vs where vs.card_id=c.id);
commit;