-- Defense in depth: client mutations of economy and trade records must go through validated RPCs.
-- These tables are RLS-protected and have no direct client write policies; explicit revokes
-- make the intended RPC-only write path clear and resilient to future policy mistakes.
revoke insert, update, delete, truncate, references, trigger
  on table public.ledger,
           public.card_instances,
           public.market_listings,
           public.mission_claims,
           public.trade_items,
           public.trade_offers,
           public.booster_inventory,
           public.secret_attempts,
           public.secret_challenges
  from anon, authenticated;
