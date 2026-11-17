# Gaycha Club — architecture notes

## Current structure
- `index.html`: application shell, current page composition and legacy application flows.
- `assets/js/utils.js`: shared escaping, DOM lookup, rarity metadata, error presentation, request locks, debounce, pagination and public-data cache helpers.
- `assets/js/card-renderer.js`: reusable card markup renderer with injected dependencies.
- `assets/js/i18n.js` + `i18n/*.json`: lightweight JSON dictionary loader for FR/EN/ES; the existing larger translation map remains as a compatibility fallback while strings are migrated progressively.
- `assets/css/tokens.css`: shared design tokens and forced-colors/high-contrast overrides.
- `tests/card-renderer.test.cjs`: renderer, rarity ranking and pagination tests.

## Routing and rendering
The existing app now supports hash-based SPA routes (for example `#collection`, `#booster`, `#admin`) and browser back/forward navigation. Views are still rendered by the existing application shell; converting every view into a separate physical page is intentionally deferred to avoid breaking authentication state and Supabase flows.

## Data caching
Only the public card catalogue (including public series/venue metadata returned by its join) is cached in browser storage for five minutes. A stale value can render immediately while a fresh request runs. User profiles, balances, inventory, messages, trades, admin data and RPC results are never cached by this helper. No CDN speed-up percentage is claimed without measurement.

## Safety and state
Mutating actions should use a keyed request lock and server-side idempotency keys wherever the RPC supports them. The booster opening flow already sets its busy flag synchronously. Never cache or optimistically alter a balance or trade result.

## Security deployment boundary
See [SECURITY-HEADERS.md](SECURITY-HEADERS.md). GitHub Pages cannot apply arbitrary response headers through a repository file. The in-document CSP is a compatibility baseline, not a strict nonce-based policy because the legacy app still contains inline scripts and styles.
