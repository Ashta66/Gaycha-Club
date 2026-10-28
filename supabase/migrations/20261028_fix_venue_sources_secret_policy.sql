-- Fix: the venue_sources SELECT policy must not read secret_challenges directly.
-- The table is intentionally not exposed to anon/authenticated; reward_card_id in
-- secret_discoveries is sufficient to verify whether the current user unlocked a card.
DROP POLICY IF EXISTS venue_sources_read_published ON public.venue_sources;
CREATE POLICY venue_sources_read_published ON public.venue_sources
FOR SELECT TO anon, authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.cards c
    WHERE c.id = venue_sources.card_id
      AND c.status = 'publie'::public.publish_status
      AND (
        NOT c.is_secret
        OR EXISTS (
          SELECT 1
          FROM public.secret_discoveries d
          WHERE d.user_id = (SELECT auth.uid())
            AND d.reward_card_id = c.id
        )
      )
  )
);
