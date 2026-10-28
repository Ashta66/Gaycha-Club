DROP POLICY IF EXISTS series_catalog_manager_write ON public.series;
DROP POLICY IF EXISTS series_catalog_manager_insert ON public.series;
DROP POLICY IF EXISTS series_catalog_manager_update ON public.series;
CREATE POLICY series_catalog_manager_insert
ON public.series FOR INSERT TO authenticated
WITH CHECK (public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]));
CREATE POLICY series_catalog_manager_update
ON public.series FOR UPDATE TO authenticated
USING (public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]))
WITH CHECK (public.is_staff(ARRAY['admin','catalog_manager']::public.app_role[]));