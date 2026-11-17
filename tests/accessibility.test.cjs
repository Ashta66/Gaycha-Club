const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');
const tokens = fs.readFileSync('assets/css/tokens.css', 'utf8');

test('page exposes a skip link and a single main landmark', () => {
  assert.match(html, /<a class="skip-link" href="#main">Aller au contenu principal<\/a>/);
  assert.equal((html.match(/<main id="main"/g) || []).length, 1);
});

test('keyboard focus and forced-colors styles are present', () => {
  assert.match(html, /:focus-visible/);
  assert.match(tokens, /@media\s*\(forced-colors:\s*active\)/);
});

test('card zoom is a labelled modal dialog with a close control', () => {
  assert.match(html, /setAttribute\('role','dialog'\)/);
  assert.match(html, /setAttribute\('aria-modal','true'\)/);
  assert.match(html, /Fermer le zoom de la carte/);
});

test('public catalogue cache is isolated from account and transaction queries', () => {
  assert.match(html, /staleWhileRevalidate\('public-cards-v1'/);
  assert.match(html, /sb\.from\('cards'\)/);
  assert.doesNotMatch(html, /staleWhileRevalidate\('(profile|balance|inventory|trades|messages)/);
});

test('both card grids paginate to twenty entries', () => {
  assert.match(html, /paginate\(shown,collectionPage,20\)/);
  assert.match(html, /paginate\(shown,catalogPage,20\)/);
});
