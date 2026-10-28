-- Gaycha Club batch 18: add three additional venue drafts in Strasbourg and Nice.
-- Cards remain drafts, with no images and no implied photo licence.
begin;

insert into public.cards (series_id, number, name, rarity, bio, spec, anecdote, is_fictional, rights_checked, status, is_secret)
select v.series_id, v.number, v.name, 'commun', v.bio, v.spec, v.anecdote, false, false, 'brouillon', false
from (values
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,51,'Canapé Queer · Strasbourg','Bar queer de Strasbourg, espace convivial et communautaire dans le quartier de la Krutenau.','20 rue des Couples, 67000 Strasbourg · Vérifier la programmation et les horaires avant visite.','Un lieu queer référencé dans les agendas locaux récents.'),
 ('4e8c168b-1552-45ee-b362-cbd904b84b29'::uuid,52,'Rainbow Bar · Nice','Bar LGBTQ+ du quartier du Port à Nice, orienté cocktails et rencontres conviviales.','9 rue Bonaparte, 06300 Nice · Horaires à confirmer auprès du lieu.','Une adresse LGBTQ+ du quartier du Port.'),
 ('55749559-9946-4ffa-9581-9df6409f2e65'::uuid,24,'L’Oméga Club · Nice','Discothèque gay-friendly niçoise proposant des soirées DJ et une piste de danse.','8 passage Émile-Négrin, 06000 Nice · Consulter les annonces de soirée avant visite.','Une adresse de nuit orientée danse et événements.')
) as v(series_id,number,name,bio,spec,anecdote)
where not exists (select 1 from public.cards c where c.series_id=v.series_id and c.number=v.number and c.name=v.name);

insert into public.venue_sources (card_id, venue_type, city, country, official_url, description_source_url, image_source_url, image_license, verification_status, last_verified_at, notes)
select c.id,
 case when c.series_id='55749559-9946-4ffa-9581-9df6409f2e65' then 'discotheque' else 'bar' end,
 case when c.name='Canapé Queer · Strasbourg' then 'Strasbourg' else 'Nice' end,
 'France', null,
 case when c.name='Canapé Queer · Strasbourg' then 'https://agendalgbt.com/strasbourg'
      when c.name='Rainbow Bar · Nice' then 'https://maps.lafamillelgbt.fr/lieux/'
      else 'https://cruzd.fr/entre-meufs/events/themes/soiree-dansante' end,
 null,
 'Aucune licence de réutilisation établie ; demander une autorisation explicite ou utiliser une image sous licence vérifiable.',
 'vérifié', now(),
 'Lot 18 — fiche ajoutée en brouillon à partir de répertoires et annonces de soirées récents. Vérifier directement les coordonnées, l’activité régulière et les horaires. Aucun visuel intégré et aucun droit photo présumé.'
from public.cards c
where c.name in ('Canapé Queer · Strasbourg','Rainbow Bar · Nice','L’Oméga Club · Nice')
and not exists (select 1 from public.venue_sources vs where vs.card_id=c.id);

commit;