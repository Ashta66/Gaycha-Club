-- Enforce bilateral blocks for trades and release pending trade reservations.
-- Lock order for trade/block operations is profiles (UUID order) -> trade_offers -> card_instances.
-- This prevents a block/accept race from leaving an accepted offer after a block commits.

CREATE OR REPLACE FUNCTION public.propose_trade(
  p_recipient text,
  p_give uuid[],
  p_get uuid[],
  p_offer_coins bigint DEFAULT 0,
  p_request_coins bigint DEFAULT 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  pr public.profiles;
  rc public.profiles;
  recipient_id uuid;
  oid uuid;
  n int := 0;
  g uuid;
  i record;
BEGIN
  IF u IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;

  SELECT p.id
    INTO recipient_id
    FROM public.profiles p
   WHERE lower(p.username) = lower(btrim(coalesce(p_recipient, '')));

  IF recipient_id IS NULL OR recipient_id = u THEN
    RAISE EXCEPTION 'unknown recipient';
  END IF;

  -- Always lock both participants in the same order, including reciprocal proposals.
  PERFORM 1
    FROM public.profiles p
   WHERE p.id IN (u, recipient_id)
   ORDER BY p.id
   FOR UPDATE;

  SELECT * INTO pr FROM public.profiles p WHERE p.id = u;
  SELECT * INTO rc FROM public.profiles p WHERE p.id = recipient_id;

  IF pr.id IS NULL OR pr.is_suspended IS DISTINCT FROM false OR pr.age_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF rc.id IS NULL OR rc.id = u OR rc.is_suspended THEN
    RAISE EXCEPTION 'unknown recipient';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM public.blocks b
     WHERE (b.blocker_id = u AND b.blocked_id = recipient_id)
        OR (b.blocker_id = recipient_id AND b.blocked_id = u)
  ) THEN
    RAISE EXCEPTION 'user blocked';
  END IF;

  p_give := coalesce(p_give, '{}');
  p_get := coalesce(p_get, '{}');
  p_offer_coins := coalesce(p_offer_coins, 0);
  p_request_coins := coalesce(p_request_coins, 0);

  IF p_offer_coins < 0 OR p_request_coins < 0 THEN
    RAISE EXCEPTION 'invalid coins';
  END IF;
  IF cardinality(p_give) + cardinality(p_get) + p_offer_coins + p_request_coins = 0 THEN
    RAISE EXCEPTION 'empty offer';
  END IF;
  IF cardinality(p_give) > 5 OR cardinality(p_get) > 5 THEN
    RAISE EXCEPTION 'too many cards';
  END IF;
  IF (SELECT count(DISTINCT x) FROM unnest(p_give) x) <> cardinality(p_give) THEN
    RAISE EXCEPTION 'duplicate instance';
  END IF;
  IF (SELECT count(DISTINCT x) FROM unnest(p_get) x) <> cardinality(p_get) THEN
    RAISE EXCEPTION 'duplicate requested card';
  END IF;
  IF (SELECT count(*) FROM public.trade_offers WHERE proposer_id = u AND status = 'pending') >= 10 THEN
    RAISE EXCEPTION 'too many pending offers';
  END IF;

  INSERT INTO public.trade_offers(proposer_id, recipient_id, offer_coins, request_coins)
  VALUES (u, recipient_id, p_offer_coins, p_request_coins)
  RETURNING id INTO oid;

  FOR i IN
    SELECT ci.id, ci.card_id
      FROM public.card_instances ci
     WHERE ci.id = ANY(p_give)
       AND ci.owner_id = u
       AND NOT ci.locked
     FOR UPDATE
  LOOP
    UPDATE public.card_instances SET locked = true WHERE id = i.id;
    INSERT INTO public.trade_items(offer_id, side, instance_id, card_id)
    VALUES (oid, 'give', i.id, i.card_id);
    n := n + 1;
  END LOOP;

  IF n <> cardinality(p_give) THEN
    RAISE EXCEPTION 'some cards unavailable';
  END IF;

  FOREACH g IN ARRAY p_get LOOP
    IF NOT EXISTS (
      SELECT 1 FROM public.cards c WHERE c.id = g AND c.status = 'publie'
    ) THEN
      RAISE EXCEPTION 'unknown card';
    END IF;
    INSERT INTO public.trade_items(offer_id, side, card_id) VALUES (oid, 'get', g);
  END LOOP;

  RETURN oid;
END
$function$;


CREATE OR REPLACE FUNCTION public.accept_trade(p_offer uuid, p_key text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  candidate_offer public.trade_offers;
  o public.trade_offers;
  a public.profiles;
  b public.profiles;
  it record;
  x uuid;
  da bigint;
BEGIN
  IF u IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;

  IF p_key IS NULL OR char_length(btrim(p_key)) < 8 OR char_length(p_key) > 200 THEN
    RAISE EXCEPTION 'invalid idempotency key';
  END IF;

  -- Read participants without locking the offer, then lock profiles first.
  -- block_user uses the same profile -> offer order, so neither can deadlock
  -- while cancelling/accepting an offer.
  SELECT * INTO candidate_offer
    FROM public.trade_offers
   WHERE id = p_offer;

  IF candidate_offer.id IS NULL
     OR candidate_offer.status <> 'pending'
     OR candidate_offer.recipient_id <> u THEN
    RAISE EXCEPTION 'offer unavailable';
  END IF;

  PERFORM 1
    FROM public.profiles p
   WHERE p.id IN (candidate_offer.proposer_id, candidate_offer.recipient_id)
   ORDER BY p.id
   FOR UPDATE;

  SELECT * INTO o
    FROM public.trade_offers
   WHERE id = p_offer
   FOR UPDATE;

  IF o.id IS NULL
     OR o.status <> 'pending'
     OR o.recipient_id <> u
     OR o.proposer_id <> candidate_offer.proposer_id
     OR o.recipient_id <> candidate_offer.recipient_id THEN
    RAISE EXCEPTION 'offer unavailable';
  END IF;
  IF o.expires_at < now() THEN
    RAISE EXCEPTION 'offer expired';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM public.blocks b
     WHERE (b.blocker_id = o.proposer_id AND b.blocked_id = o.recipient_id)
        OR (b.blocker_id = o.recipient_id AND b.blocked_id = o.proposer_id)
  ) THEN
    RAISE EXCEPTION 'user blocked';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM public.ledger l
     WHERE l.idempotency_key IN (p_key || ':p', p_key || ':r')
  ) THEN
    RAISE EXCEPTION 'duplicate request';
  END IF;

  SELECT * INTO a FROM public.profiles p WHERE p.id = o.proposer_id;
  SELECT * INTO b FROM public.profiles p WHERE p.id = o.recipient_id;

  IF a.is_suspended OR b.is_suspended
     OR a.age_confirmed_at IS NULL
     OR b.age_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF a.balance < o.offer_coins OR b.balance < o.request_coins THEN
    RAISE EXCEPTION 'insufficient funds';
  END IF;

  FOR it IN
    SELECT * FROM public.trade_items WHERE offer_id = o.id AND side = 'get'
  LOOP
    SELECT ci.id INTO x
      FROM public.card_instances ci
     WHERE ci.owner_id = o.recipient_id
       AND ci.card_id = it.card_id
       AND NOT ci.locked
     ORDER BY ci.acquired_at DESC
     LIMIT 1
     FOR UPDATE;

    IF x IS NULL THEN
      RAISE EXCEPTION 'requested card no longer available';
    END IF;

    UPDATE public.card_instances
       SET owner_id = o.proposer_id, acquired_at = now()
     WHERE id = x;
    x := NULL;
  END LOOP;

  FOR it IN
    SELECT * FROM public.trade_items WHERE offer_id = o.id AND side = 'give'
  LOOP
    UPDATE public.card_instances
       SET owner_id = o.recipient_id, locked = false, acquired_at = now()
     WHERE id = it.instance_id
       AND owner_id = o.proposer_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'offered card no longer available';
    END IF;
  END LOOP;

  da := o.request_coins - o.offer_coins;
  IF da <> 0 THEN
    UPDATE public.profiles SET balance = balance + da WHERE id = a.id;
    UPDATE public.profiles SET balance = balance - da WHERE id = b.id;

    INSERT INTO public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
    VALUES (a.id, da, 'trade', o.id, a.balance + da, p_key || ':p');
    INSERT INTO public.ledger(user_id, delta, reason, ref, balance_after, idempotency_key)
    VALUES (b.id, -da, 'trade', o.id, b.balance - da, p_key || ':r');
  END IF;

  UPDATE public.trade_offers
     SET status = 'accepted', resolved_at = now()
   WHERE id = o.id;
END
$function$;


CREATE OR REPLACE FUNCTION public.block_user(p_username text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  u uuid := auth.uid();
  target_id uuid;
BEGIN
  IF u IS NULL THEN
    RAISE EXCEPTION 'auth required';
  END IF;

  SELECT p.id
    INTO target_id
    FROM public.profiles p
   WHERE lower(p.username) = lower(btrim(coalesce(p_username, '')));

  IF target_id IS NULL OR target_id = u THEN
    RAISE EXCEPTION 'unknown user';
  END IF;

  -- Serialize against propose_trade/accept_trade using the same participant lock order.
  PERFORM 1
    FROM public.profiles p
   WHERE p.id IN (u, target_id)
   ORDER BY p.id
   FOR UPDATE;

  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = target_id) THEN
    RAISE EXCEPTION 'unknown user';
  END IF;

  INSERT INTO public.blocks(blocker_id, blocked_id)
  VALUES (u, target_id)
  ON CONFLICT DO NOTHING;

  UPDATE public.conversations
     SET status = 'declined'
   WHERE user_a = least(u, target_id)
     AND user_b = greatest(u, target_id)
     AND status = 'pending';

  -- Cancel pending offers in either direction and unlock their reserved cards.
  WITH cancelled AS (
    UPDATE public.trade_offers t
       SET status = 'cancelled', resolved_at = now()
     WHERE t.status = 'pending'
       AND (
         (t.proposer_id = u AND t.recipient_id = target_id)
         OR
         (t.proposer_id = target_id AND t.recipient_id = u)
       )
    RETURNING t.id
  )
  UPDATE public.card_instances ci
     SET locked = false
   WHERE ci.locked
     AND ci.owner_id IN (u, target_id)
     AND ci.id IN (
       SELECT ti.instance_id
         FROM public.trade_items ti
         JOIN cancelled c ON c.id = ti.offer_id
        WHERE ti.side = 'give'
          AND ti.instance_id IS NOT NULL
     );
END
$function$;
