-- Index the nullable actor reference used by site-branding audit queries.
CREATE INDEX IF NOT EXISTS site_branding_updated_by_idx
  ON public.site_branding (updated_by);
