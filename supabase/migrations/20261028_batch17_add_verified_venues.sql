-- Gaycha Club batch 17: add five verified draft venue cards and refresh two existing records.
-- Idempotent for cards already present; no publication and no image reuse rights are granted.
begin;

update public.venue_sources vs
set description_source_url = 'https://agendalgbt.com/nantes',
    official_url = null,
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 : Le Montecito est référencé séparément comme bar gay-friendly à Nantes, 6 allée Duquesne. La Licorne Noire est un autre établissement ; son site officiel ne doit pas lui être attribué. Carte conservée en brouillon, droits photo non établis.'
from public.cards c
where c.id = vs.card_id and c.name = 'Le Montecito' and vs.city = 'Nantes';

update public.venue_sources vs
set description_source_url = 'https://maps.lafamillelgbt.fr/lieux/',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 : Ramdam est référencé comme bar LGBTQIA+ au 3 rue Lascaris, Nice ; une fiche commerciale récente décrit son concept bar, expo et musique. Confirmer les horaires avant publication ; aucune photo réutilisée.'
from public.cards c
where c.id = vs.card_id and c.name = 'Ramdam' and vs.city = 'Nice';

insert into public.cards (series_id, number, name, rarity, bio, spec, anecdote, is_fictional, rights_checked, status, is_secret)
select v.series_id, v.number, v.name, 'commun', v.bio, v.spec, v.anecdote, false, false, 'brouillon', false
from (values
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,47,'La Licorne Noire','Café culturel et bar festif nantais qui célèbre les cultures afro-caribéennes et accueille les personnes LGBTQIA+, leurs proches et leurs familles.','14 bis rue de Mayence, 44000 Nantes · Programmation et horaires à vérifier sur le site officiel.','Un lieu queer qui associe culture, musique et convivialité.'),
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,48,'Le Privilège · Lille','Bar gay convivial situé dans le Vieux-Lille, avec cocktails et soirées.','2 rue Royale, 59000 Lille · Horaires à vérifier avant visite.','Une adresse historique du Vieux-Lille.'),
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,49,'Le Sling · Lille','Bar gay et cruising référencé dans les guides LGBTQ+ lillois.','32 rue Jean-Jaurès, Lille · Conditions d’accès et horaires à confirmer.','Une adresse dédiée aux rencontres adultes.'),
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,50,'Lokarria · Lille','Bar queer et LGBT-friendly dans le quartier de Wazemmes.','42 rue des Postes, 59000 Lille · Horaires à confirmer.','Un lieu de sociabilité queer au sud du centre.'),
 ('2550dab6-c62b-476e-afff-d66a78292ecb'::uuid,33,'Sauna California · Rennes','Sauna gay et mixte avec des créneaux dédiés aux hommes et des rendez-vous ouverts à toutes les orientations.','7 rue de Léon, 35000 Rennes · Consulter le calendrier officiel pour choisir la séance.','La programmation distingue les créneaux gay et les séances toutes tendances confondues.')
) as v(series_id,number,name,bio,spec,anecdote)
where not exists (select 1 from public.cards c where c.series_id=v.series_id and c.number=v.number and c.name=v.name);

insert into public.venue_sources (card_id, venue_type, city, country, official_url, description_source_url, image_source_url, image_license, verification_status, last_verified_at, notes)
select c.id,
 case when c.series_id='2550dab6-c62b-476e-afff-d66a78292ecb' then 'sauna' else 'bar' end,
 case when c.name='La Licorne Noire' then 'Nantes'
      when c.name='Sauna California · Rennes' then 'Rennes'
      else 'Lille' end,
 'France',
 case when c.name='La Licorne Noire' then 'https://www.lalicornenoire.fr/'
      when c.name='Sauna California · Rennes' then 'https://www.saunacalifornia.com/'
      else null end,
 case when c.name='La Licorne Noire' then 'https://www.lalicornenoire.fr/'
      when c.name='Sauna California · Rennes' then 'https://www.saunacalifornia.com/'
      when c.name='Le Privilège · Lille' then 'https://agendalgbt.com/lille'
      when c.name='Le Sling · Lille' then 'https://maps.lafamillelgbt.fr/lieux/'
      else 'https://agendalgbt.com/lille' end,
 case when c.name='La Licorne Noire' then 'https://www.lalicornenoire.fr/'
      when c.name='Sauna California · Rennes' then 'https://www.saunacalifornia.com/'
      else null end,
 'Aucune licence de réutilisation établie ; demander une autorisation explicite ou utiliser une image sous licence vérifiable.',
 'vérifié', now(),
 'Lot 17 — fiche ajoutée en brouillon après vérification de sources accessibles le 28/10/2026. Ne pas publier avant contrôle des coordonnées et horaires. Aucun visuel intégré ; la présence d’images sur le site officiel ne vaut pas autorisation.'
from public.cards c
where c.name in ('La Licorne Noire','Le Privilège · Lille','Le Sling · Lille','Lokarria · Lille','Sauna California · Rennes')
and not exists (select 1 from public.venue_sources vs where vs.card_id=c.id);

commit;