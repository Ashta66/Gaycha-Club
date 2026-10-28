-- Cover foreign keys used by the card-version audit history.
create index if not exists card_versions_card_id_idx
  on public.card_versions (card_id);
create index if not exists card_versions_changed_by_idx
  on public.card_versions (changed_by);
