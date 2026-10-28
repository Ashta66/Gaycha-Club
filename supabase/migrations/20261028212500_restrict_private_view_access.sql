-- Private user-specific views must not be exposed to anonymous clients.
-- They are security_invoker views; authenticated users retain SELECT and are
-- still constrained by the underlying table RLS policies.
revoke all privileges on table public.blocked_view, public.conversations_view,
  public.trade_items_view, public.trades_view from anon;
-- Views are read models only; prevent any accidental writes through them.
revoke insert, update, delete, truncate, references, trigger on table
  public.blocked_view, public.conversations_view, public.leaderboard,
  public.market_view, public.public_profiles, public.trade_items_view,
  public.trades_view from anon, authenticated;
