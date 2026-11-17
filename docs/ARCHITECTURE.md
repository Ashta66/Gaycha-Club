# Gaycha Club — architecture notes

## Current structure
- `index.html`: application shell, current page composition and legacy application flows.
- `assets/js/utils.js`: shared escaping, DOM lookup, rarity metadata, error presentation, request locks, debounce, pagination and public-data cache helpers.
- `assets/js/card-renderer.js`: reusable card markup renderer with injected dependencies.
- `assets/js/i18n.js` + `i18n/*.json`: lightweight JSON dictionary loader for FR/EN/ES; the existing larger translation map remains as a compatibility fallback while strings are migrated progressively.
- `assets/css/tokens.css`: shared design tokens and forced-colors/high-contrast overrides.
- `tests/card-renderer.test.cjs`: renderer, rarity ranking and pagination tests.

## Routing and rendering
The existing app now supports hash-based SPA routes (for example `#collection`, `#booster`, `#admin`) and browser back/forward navigation. The login view is also route-addressable. Views are still rendered by the existing application shell; converting every view into a separate physical page is intentionally deferred to avoid breaking authentication state and Supabase flows.

## Accessibility and mobile continuity
- The collection and public catalogue render at most 20 cards per page.
- The card zoom uses a labelled modal dialog, supports Escape through the native dialog behavior, restores focus, and avoids touch-pointer tilt gestures.
- Card tiles support Enter and Space activation.
- Collection filters, active route and scroll position are saved in session storage before a refresh and restored after the view is rebuilt. The browser's native pull-to-refresh gesture is not intercepted.
- Resize, scroll persistence and high-frequency filter input are debounced.

## Data caching
Only the public card catalogue (including public series/venue metadata returned by its join) is cached in browser storage for five minutes. A stale value can render immediately while a fresh request runs. User profiles, balances, inventory, messages, trades, admin data and RPC results are never cached by this helper. No CDN speed-up percentage is claimed without measurement. The 40–60% estimate is a target hypothesis, not a measured result.

## Safety and state
Mutating actions should use a keyed request lock and server-side idempotency keys wherever the RPC supports them. The booster opening flow already sets its busy flag synchronously. Never cache or optimistically alter a balance or trade result.

## Security deployment boundary
See [SECURITY-HEADERS.md](SECURITY-HEADERS.md). GitHub Pages cannot apply arbitrary response headers through a repository file. The in-document CSP is a compatibility baseline, not a strict nonce-based policy because the legacy app still contains inline scripts and styles. JSON dictionaries are now loaded for common interface strings, but the older inline EN/ES map remains as a fallback; complete string extraction is incremental. Likewise, design tokens are externalized while the remaining legacy CSS is still inline and will need a gradual BEM/component migration.
