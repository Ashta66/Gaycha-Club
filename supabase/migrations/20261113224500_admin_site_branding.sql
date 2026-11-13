-- Global brand assets editable by main administrators.
CREATE TABLE IF NOT EXISTS public.site_branding (
  id smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  logo_url text,
  favicon_url text,
  logo_alt text NOT NULL DEFAULT 'Gaycha Club',
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT site_branding_logo_https CHECK (logo_url IS NULL OR logo_url ~ '^https://'),
  CONSTRAINT site_branding_favicon_https CHECK (favicon_url IS NULL OR favicon_url ~ '^https://')
);

ALTER TABLE public.site_branding ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.site_branding FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.site_branding TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.site_branding TO authenticated;

DROP POLICY IF EXISTS site_branding_public_read ON public.site_branding;
CREATE POLICY site_branding_public_read
  ON public.site_branding FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS site_branding_admin_insert ON public.site_branding;
CREATE POLICY site_branding_admin_insert
  ON public.site_branding FOR INSERT
  TO authenticated
  WITH CHECK (public.is_staff(ARRAY['admin'::public.app_role]));

DROP POLICY IF EXISTS site_branding_admin_update ON public.site_branding;
CREATE POLICY site_branding_admin_update
  ON public.site_branding FOR UPDATE
  TO authenticated
  USING (public.is_staff(ARRAY['admin'::public.app_role]))
  WITH CHECK (public.is_staff(ARRAY['admin'::public.app_role]));

INSERT INTO public.site_branding (id, logo_alt)
VALUES (1, 'Gaycha Club')
ON CONFLICT (id) DO NOTHING;
