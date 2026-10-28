-- Gaycha Club — batch 13: refresh venue activity sources (Lille, Toulouse, Montpellier)
-- Metadata only. No cards are published and no image reuse rights are inferred.
begin;

update public.venue_sources vs set
  description_source_url = 'https://agendalgbt.com/lille',
  verification_status = 'vérifié',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — guide Agenda LGBT Lille mis à jour en octobre 2026 : établissement encore répertorié. Carte conservée en brouillon ; adresse/horaires à confirmer directement et droits photo non accordés par cette source.'
from public.cards c
where c.id = vs.card_id and c.status = 'brouillon' and vs.city = 'Lille'
  and c.name in ('Sauna Les Bains', 'Sauna Soho', 'Silom Bar', 'Slay Club');

update public.venue_sources vs set
  description_source_url = 'https://agendalgbt.com/guides/quartier-gay-de-toulouse-ou-sortir-et-bonnes-adresses-lgbt',
  verification_status = 'vérifié',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — guide Agenda LGBT Toulouse mis à jour le 23/09/2026 confirme encore l’établissement. Carte conservée en brouillon ; horaires/adresse à revérifier avant publication et aucun droit photo déduit de la source.'
from public.cards c
where c.id = vs.card_id and c.status = 'brouillon' and vs.city = 'Toulouse'
  and c.name in ('La Gougnotte', 'Le KS Sauna');

update public.venue_sources vs set
  description_source_url = 'https://agendalgbt.com/montpellier',
  verification_status = 'vérifié',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — Agenda LGBT Montpellier mis à jour en octobre 2026 répertorie encore cet établissement. Carte conservée en brouillon ; adresse/horaires à confirmer et droits des images non établis.'
from public.cards c
where c.id = vs.card_id and c.status = 'brouillon' and vs.city = 'Montpellier'
  and c.name in ('Madrediosa', 'Koncept Sauna');

commit;