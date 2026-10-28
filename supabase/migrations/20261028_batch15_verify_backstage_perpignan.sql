-- Gaycha Club — batch 15: confirm current activity for Backstage, Perpignan
-- Keeps the card in draft and preserves conservative image-rights handling.
update public.venue_sources vs set
  verification_status = 'vérifié',
  description_source_url = 'https://centrelgbt66.com/evenement/10eme-festival-et-alors-au-backstage-en-cine-concert/',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — activité confirmée par le Centre LGBT+66 (événement du 04/10/2026 au Backstage, 1 rue Pierre Puiggary) et QLIST mis à jour le 17/10/2026. La carte reste en brouillon. Le retrait du visuel externe est maintenu ; droits photo toujours non accordés.'
from public.cards c
where c.id = vs.card_id and c.name = 'Backstage' and vs.city = 'Perpignan' and c.status = 'brouillon';