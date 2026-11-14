-- Staff-only, privacy-minimized directory for the admin Accounts tab.
-- No email addresses or authentication metadata are exposed.
CREATE OR REPLACE FUNCTION public.admin_list_accounts(
  p_limit integer DEFAULT 25,
  p_offset integer DEFAULT 0,
  p_search text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  actor_is_admin boolean;
  clean_search text := NULLIF(BTRIM(COALESCE(p_search, '')), '');
  total_count integer;
  account_rows jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.is_staff(ARRAY['admin','moderator']::public.app_role[]) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100
     OR p_offset IS NULL OR p_offset < 0 OR p_offset > 100000 THEN
    RAISE EXCEPTION 'invalid pagination';
  END IF;

  actor_is_admin := public.is_staff(ARRAY['admin']::public.app_role[]);

  SELECT count(*)::integer
    INTO total_count
    FROM public.profiles p
   WHERE clean_search IS NULL
      OR p.username ILIKE '%' || clean_search || '%';

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', page.id,
        'username', page.username,
        'role', page.role::text,
        'is_suspended', page.is_suspended,
        'age_confirmed', page.age_confirmed_at IS NOT NULL,
        'created_at', page.created_at,
        'balance', CASE WHEN actor_is_admin THEN page.balance ELSE NULL END,
        'xp', CASE WHEN actor_is_admin THEN page.xp ELSE NULL END,
        'booster_inventory',
          CASE WHEN actor_is_admin THEN COALESCE((
            SELECT jsonb_agg(
              jsonb_build_object(
                'slug', bt.slug,
                'name', bt.name,
                'quantity', bi.quantity
              )
              ORDER BY bt.price, bt.name
            )
            FROM public.booster_inventory bi
            JOIN public.booster_types bt ON bt.id = bi.booster_type_id
            WHERE bi.user_id = page.id
              AND bi.quantity > 0
          ), '[]'::jsonb) ELSE '[]'::jsonb END
      )
      ORDER BY page.created_at DESC, page.username
    ),
    '[]'::jsonb
  )
    INTO account_rows
    FROM (
      SELECT p.id, p.username, p.role, p.is_suspended,
             p.age_confirmed_at, p.created_at, p.balance, p.xp
        FROM public.profiles p
       WHERE clean_search IS NULL
          OR p.username ILIKE '%' || clean_search || '%'
       ORDER BY p.created_at DESC, p.username
       LIMIT p_limit OFFSET p_offset
    ) page;

  RETURN jsonb_build_object(
    'total', total_count,
    'accounts', account_rows
  );
END
$function$;

REVOKE ALL ON FUNCTION public.admin_list_accounts(integer, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_list_accounts(integer, integer, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_list_accounts(integer, integer, text) TO authenticated;
