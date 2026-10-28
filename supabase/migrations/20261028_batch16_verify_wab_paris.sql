-- Gaycha Club — batch 16: verify WAB, Paris
-- WAB is described as a queer bar by Queer Paris; the card remains unpublished.
update public.venue_sources vs set
  description_source_url = 'https://queer.paris/lieux/wab',
  verification_status = 'vérifié',
  last_verified_at = now(),
  notes = coalesce(vs.notes, '') || E'\nAudit du 28/10/2026 — fiche Queer Paris récemment indexée : WAB, 16 boulevard Jules Ferry, Paris 11e, bar queer ouvert depuis 2020. La carte reste en brouillon ; confirmer directement les horaires et les droits d’utilisation de tout visuel avant publication.'
from public.cards c
where c.id = vs.card_id and c.name = 'WAB — We Are Brewers' and vs.city = 'Paris' and c.status = 'brouillon';