# Gaycha Club — Phase 2 test branch

This is a draft branch based on the latest `main`. It is not approved for merge or deployment.

## Implemented in this branch

- Google OAuth sign-in alongside email/password.
- A profile screen with an explicit “Lier mon compte Google” action, intended to be started while signed into the existing account.
- Hybrid mobile navigation with four main sections and a “Plus” menu, plus two-column mobile card grids.
- A more restrained visual style: reduced glow, softer surfaces, and less reliance on rainbow gradients.
- Exchange estimates based on available market listing prices, visible uncertainty when prices are missing, an imbalance warning, a same-card-on-both-sides check, and a final confirmation recap.
- A batch-credit workflow in the Admin panel using the existing `admin_grant_coins` RPC. It validates the list, previews the total, asks for confirmation, and reports each result. The existing RPC's 1–1,000 credits per-player limit is preserved. The RPC's SQL definition and server-side role enforcement are not included in this repository, so that authorization must be independently verified before merge or use.

## Important limits

- Batch credits call the existing RPC one player at a time. If a call fails mid-batch, earlier successful credits remain applied; the UI reports successes and failures rather than pretending the operation is atomic. The SQL implementation is not in the repository, so its admin-role check and audit behavior are not yet verified.
- The audit screen now surfaces actor/target and previous/new balance fields when those fields exist in the rows. This branch does not alter the database logging schema, so it cannot guarantee that the server currently records every requested field.
- A secure booster-gifting RPC is not present in the repository, so the “offer one or more boosters” operation is not wired to an invented function name.
- Admin controls for trades, missions, economy, and maintenance also need their actual server-side RPCs and policies reviewed before adding mutating actions. The current repository has no SQL migrations or function definitions for those capabilities.

## Google setup required

Enable Google in Supabase Authentication, configure the OAuth client credentials in the Supabase dashboard (do not put a client secret in this repository), and add the deployed URL to the allowed redirect URLs. Test sign-in and explicit identity linking with a test account before release. Linking must be tested carefully so existing collection and balance remain attached to the original account.

## Validation status

- JavaScript syntax parsing: passed after the latest edits.
- Live browser testing, Supabase RPC/RLS behavior, Google provider configuration, mobile-device layout, and real account-linking behavior: not yet tested.
- No database migration was applied.
- `main` has not been modified by this branch.
