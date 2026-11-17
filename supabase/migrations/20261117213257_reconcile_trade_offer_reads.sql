-- Reconcile the trade-offer read-marker schema already present in production.
-- Idempotent so this also provisions the table on a clean database.
CREATE TABLE IF NOT EXISTS public.trade_offer_reads (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  offer_id uuid NOT NULL REFERENCES public.trade_offers(id) ON DELETE CASCADE,
  read_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT trade_offer_reads_pkey PRIMARY KEY (user_id, offer_id)
);

CREATE INDEX IF NOT EXISTS trade_offer_reads_offer_id_idx
  ON public.trade_offer_reads (offer_id);

ALTER TABLE public.trade_offer_reads ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.trade_offer_reads FROM PUBLIC, anon;
GRANT SELECT, INSERT ON public.trade_offer_reads TO authenticated;

DROP POLICY IF EXISTS "Participants mark their own trade offers as read" ON public.trade_offer_reads;
CREATE POLICY "Participants mark their own trade offers as read"
  ON public.trade_offer_reads
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.trade_offers o
      WHERE o.id = trade_offer_reads.offer_id
        AND (o.proposer_id = (SELECT auth.uid()) OR o.recipient_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Users read their own trade offer read markers" ON public.trade_offer_reads;
CREATE POLICY "Users read their own trade offer read markers"
  ON public.trade_offer_reads
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
