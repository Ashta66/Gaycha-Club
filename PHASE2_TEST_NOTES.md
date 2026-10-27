# Gaycha Club — Phase 2 test notes

This branch is a **draft test branch**. It must not be merged or deployed until the remaining backend work and live checks are complete.

## Included in this pass

- Google OAuth sign-in alongside email/password.
- Explicit Google identity-link action in the signed-in profile, intended to be started from the existing account to preserve its collection and balance.
- Hybrid mobile navigation: main sections in a fixed bottom bar, remaining sections under “Plus”.
- Mobile card and booster grids adapted to two columns.
- A more restrained editorial visual treatment with less glow and less rainbow-gradient usage.
- Exchange recap now estimates values from available market listings, flags large estimated gaps, notes missing prices, blocks the same card appearing on both sides, and repeats the estimate in the final confirmation.

## Google OAuth setup still required

Configure Google as an enabled provider in Supabase Authentication, enter the Google OAuth client credentials in the Supabase dashboard (never in this repository), and add the deployed site URL to Supabase's allowed redirect URLs. Also verify identity linking behavior with a test account before considering release. The frontend code alone does not enable Google sign-in.

## Admin features intentionally not implemented yet

The repository currently contains no database migrations or SQL definitions for admin roles, credit transactions, booster grants, or row-level security policies. The visible client code also does not expose an admin role check. Do not implement credit adjustments or booster grants by directly updating tables from the browser.

Before implementing the admin panel, inspect the live Supabase schema and policies, then add server-side, admin-authorized operations with an audit trail. Required behavior:
- Batch credit grants with pseudo-to-user resolution and a clear preview before applying.
- An immutable operation log containing actor, target, amount, reason, previous/new balance, and timestamp.
- Booster grants restricted to authorized administrators and validated server-side.
- Separate permissions for player management, card management, economy, trades, reports, missions, stats, and maintenance.

## Verification status

- JavaScript syntax parse: passed after the latest edits.
- Browser interactions, Google provider configuration, Supabase RLS/RPC behavior, mobile visual testing, and real exchange flows: **not yet tested**.
- No Supabase migration was applied.
- No changes were made to `main`; this branch is not the public-site release.
