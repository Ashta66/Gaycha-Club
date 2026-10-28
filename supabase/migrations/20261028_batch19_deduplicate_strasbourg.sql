-- Gaycha Club batch 19: resolve Strasbourg duplicate and refresh two current listings.
begin;

update public.cards set status = 'archive'
where id = '1e4d49f3-852b-419e-b26d-c62d73c91a0f';

update public.venue_sources
set verification_status = 'à vérifier',
    last_verified_at = now(),
    notes = coalesce(notes, '') || E'\nLot 19 — doublon détecté : même établissement que la fiche canonique « Canapé Queer » (Strasbourg). Variante archivée sans suppression ; utiliser la fiche canonique n°31.'
where card_id = '1e4d49f3-852b-419e-b26d-c62d73c91a0f';

update public.venue_sources
set description_source_url = 'https://www.queerbourg.fr/lieux',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = coalesce(notes, '') || E'\nAudit du 28/10/2026 — Queerbourg référence Canapé Queer au 20 rue des Couples et annonce des événements à venir ; Agenda LGBT Strasbourg le décrit comme bar queer actif. Adresse retenue 20 rue des Couples ; horaires à confirmer. Aucun droit photo présumé.'
where card_id = 'b3b6264a-98c8-4009-8ba4-9e2b53b9d0a8';

update public.venue_sources
set description_source_url = 'https://agendalgbt.com/strasbourg',
    verification_status = 'vérifié',
    last_verified_at = now(),
    notes = coalesce(notes, '') || E'\nAudit du 28/10/2026 — Agenda LGBT Strasbourg mis à jour en octobre 2026 référence le Sauna Equateur, 5 rue de Rosheim, comme sauna gay actif. Fiche conservée en brouillon ; horaires à vérifier auprès du lieu et droits visuels non établis.'
where card_id = 'fd6ae886-b57b-46f4-8ba8-c6012b7102c9';

commit;