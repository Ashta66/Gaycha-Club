# GitHub Pages security headers

GitHub Pages does not provide a repository-level `_headers` mechanism for arbitrary response headers. Do not add a fake `_headers` file and assume it is enforced.

## Controls that can be applied in this static deployment
- A conservative Content Security Policy can be delivered with a `<meta http-equiv="Content-Security-Policy">` element.
- The current app still contains inline JavaScript and inline styles, loads Supabase JS from jsDelivr, Google Fonts, and user/venue images from HTTPS sources. A policy therefore needs `'unsafe-inline'` and carefully scoped HTTPS hosts until scripts/styles are externalized and nonce/hash deployment is available.
- `frame-ancestors`, `X-Frame-Options`, `Strict-Transport-Security`, `X-Content-Type-Options`, and `Referrer-Policy` are response-header controls; a meta tag cannot faithfully replace all of them.

## Recommended when moving behind a configurable edge/server
Set:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN` (or CSP `frame-ancestors 'self'`)
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`
- A tested CSP with `object-src 'none'`, `base-uri 'self'`, `frame-ancestors 'self'`, and narrowly scoped `script-src`, `style-src`, `img-src`, `connect-src`, and `font-src`.

Do not claim header protection is active on GitHub Pages until response headers are verified from the deployed site.
