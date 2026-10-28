-- Gaycha Club — batch 14: audit Bordeaux and Nantes activity
-- Metadata only; closed venue is archived, never deleted. No images are added.
begin;

update public.venue_sources vs set
  description_source_url = 'https://www.bordeaux-tourisme.com/sortir/bars/queer-lgbt',
  verification_status = 'vérifié',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — Office de tourisme de Bordeaux confirme le Buster au 34 rue de Cursol ; guide Agenda LGBT octobre 2026 confirme aussi Philippe Bar Queer au 31 rue Bouquière. Fiches maintenues en brouillon ; droits des photos non établis.'
from public.cards c
where c.id = vs.card_id and c.status = 'brouillon' and vs.city = 'Bordeaux'
  and c.name in ('Buster Bar', 'Philippe Bar Queer');

update public.venue_sources vs set
  description_source_url = 'https://agendalgbt.com/en/bordeaux/nightlife',
  verification_status = 'fermé',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — Agenda LGBT indique que l’Ultra Klubs a fermé et ne le liste plus comme club actif. Fiche archivée pour garder la trace historique ; ne pas réactiver sans preuve récente de réouverture.'
from public.cards c
where c.id = vs.card_id and vs.city = 'Bordeaux' and c.name = 'L’Ultra Klub';

update public.cards c set status = 'archive'
where c.name = 'L’Ultra Klub'
  and exists (select 1 from public.venue_sources vs where vs.card_id = c.id and vs.city = 'Bordeaux' and vs.verification_status = 'fermé');

update public.venue_sources vs set
  description_source_url = 'https://agendalgbt.com/nantes',
  verification_status = 'vérifié',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — Agenda LGBT Nantes mis à jour en octobre 2026 annonce encore des soirées au CO2 Club Origin et référence le sauna Steamer. Fiches conservées en brouillon ; confirmer les coordonnées et horaires directement avant publication ; aucun droit photo déduit.'
from public.cards c
where c.id = vs.card_id and c.status = 'brouillon' and vs.city = 'Nantes'
  and c.name in ('CO2 Club Origin', 'Steamer-Nantes');

commit;