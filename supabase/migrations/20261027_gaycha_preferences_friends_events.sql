-- Gaycha Club : préférences, amitiés, événements et durcissement des profils.
-- Cette migration documente les changements appliqués au projet Supabase le 27/10/2026.

-- Empêche l'écriture directe de champs de profil sensibles via la Data API.
REVOKE INSERT ON TABLE public.profiles FROM anon, authenticated;
REVOKE UPDATE ON TABLE public.profiles FROM anon;

CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  theme text NOT NULL DEFAULT 'bright' CHECK (theme IN ('soft','bright','max')),
  reduced_motion boolean NOT NULL DEFAULT false,
  profile_visible boolean NOT NULL DEFAULT true,
  notifications_enabled boolean NOT NULL DEFAULT true,
  language text NOT NULL DEFAULT 'fr' CHECK (language IN ('fr','en','es')),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.user_preferences FROM anon, public;
GRANT SELECT, INSERT, UPDATE ON TABLE public.user_preferences TO authenticated;
DROP POLICY IF EXISTS user_preferences_own ON public.user_preferences;
CREATE POLICY user_preferences_own ON public.user_preferences
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE TABLE IF NOT EXISTS public.friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT friendships_no_self CHECK (requester_id <> recipient_id),
  CONSTRAINT friendships_unique_direction UNIQUE (requester_id, recipient_id)
);
CREATE INDEX IF NOT EXISTS friendships_recipient_status_idx ON public.friendships(recipient_id,status);
CREATE INDEX IF NOT EXISTS friendships_requester_status_idx ON public.friendships(requester_id,status);
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.friendships FROM anon, public;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.friendships TO authenticated;
DROP POLICY IF EXISTS friendships_read_participant ON public.friendships;
CREATE POLICY friendships_read_participant ON public.friendships FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = requester_id OR (SELECT auth.uid()) = recipient_id);
DROP POLICY IF EXISTS friendships_request_self ON public.friendships;
CREATE POLICY friendships_request_self ON public.friendships FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = requester_id AND status = 'pending' AND requester_id <> recipient_id);
DROP POLICY IF EXISTS friendships_recipient_respond ON public.friendships;
CREATE POLICY friendships_recipient_respond ON public.friendships FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = recipient_id AND status = 'pending')
  WITH CHECK ((SELECT auth.uid()) = recipient_id AND status IN ('accepted','rejected'));
DROP POLICY IF EXISTS friendships_cancel_pending ON public.friendships;
CREATE POLICY friendships_cancel_pending ON public.friendships FOR DELETE TO authenticated
  USING (((SELECT auth.uid()) = requester_id OR (SELECT auth.uid()) = recipient_id) AND status = 'pending');

CREATE TABLE IF NOT EXISTS public.club_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL CHECK (char_length(title) BETWEEN 3 AND 100),
  description text NOT NULL DEFAULT '' CHECK (char_length(description) <= 2000),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT club_events_valid_dates CHECK (ends_at IS NULL OR ends_at >= starts_at)
);
CREATE INDEX IF NOT EXISTS club_events_schedule_idx ON public.club_events(active,starts_at);
ALTER TABLE public.club_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.club_events FROM anon, public;
GRANT SELECT ON TABLE public.club_events TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.club_events TO authenticated;
DROP POLICY IF EXISTS club_events_read_public ON public.club_events;
CREATE POLICY club_events_read_public ON public.club_events FOR SELECT TO anon, authenticated
  USING (active OR is_staff(ARRAY['admin'::app_role,'moderator'::app_role]));
DROP POLICY IF EXISTS club_events_staff_insert ON public.club_events;
CREATE POLICY club_events_staff_insert ON public.club_events FOR INSERT TO authenticated
  WITH CHECK (is_staff(ARRAY['admin'::app_role,'moderator'::app_role]) AND (created_by IS NULL OR created_by = (SELECT auth.uid())));
DROP POLICY IF EXISTS club_events_staff_update ON public.club_events;
CREATE POLICY club_events_staff_update ON public.club_events FOR UPDATE TO authenticated
  USING (is_staff(ARRAY['admin'::app_role,'moderator'::app_role]))
  WITH CHECK (is_staff(ARRAY['admin'::app_role,'moderator'::app_role]));
DROP POLICY IF EXISTS club_events_staff_delete ON public.club_events;
CREATE POLICY club_events_staff_delete ON public.club_events FOR DELETE TO authenticated
  USING (is_staff(ARRAY['admin'::app_role,'moderator'::app_role]));

-- Les profils masqués disparaissent de l'annuaire public et du classement.
CREATE OR REPLACE VIEW public.public_profiles AS
  SELECT p.id,p.username,p.bio,p.xp,p.created_at
  FROM public.profiles p
  LEFT JOIN public.user_preferences up ON up.user_id=p.id
  WHERE COALESCE(up.profile_visible,true) = true;

CREATE OR REPLACE VIEW public.leaderboard AS
  SELECT p.username,p.xp,
    (SELECT count(DISTINCT ci.card_id) FROM public.card_instances ci WHERE ci.owner_id=p.id) AS cards_found
  FROM public.profiles p
  LEFT JOIN public.user_preferences up ON up.user_id=p.id
  WHERE NOT p.is_suspended AND COALESCE(up.profile_visible,true) = true
  ORDER BY p.xp DESC,
    (SELECT count(DISTINCT ci.card_id) FROM public.card_instances ci WHERE ci.owner_id=p.id) DESC
  LIMIT 50;
