const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');

test('SPA router calls the browser History API explicitly', () => {
  assert.match(html, /window\.history\.pushState\(/);
  assert.doesNotMatch(html, /(?<![\w.])history\.pushState\(/);
});

test('startup reports rejected initialization instead of leaving a blank page', () => {
  assert.match(html, /demarrage-application/);
  assert.match(html, /\.catch\(error\s*=>\s*handleError\(error,'demarrage-application',app\)\)/);
});

test('catalogue metadata failure falls back to core card data', () => {
  assert.match(html, /public-cards-v2/);
  assert.match(html, /select\('\*,series\(name,color_a,color_b\)'\)/);
  assert.match(html, /select\('\*'\)\.order\('number'\)/);
});

test('catalogue failure does not block session routing or the home view', () => {
  assert.match(html, /initialisation-session:\+v/);
  assert.match(html, /Catalogue indisponible ; affichage de la rubrique sans données cartes/);
  assert.doesNotMatch(html, /try\{await refresh\(\);if\(!cards\.length\)await loadCards\(\)\}catch/);
});

test('activity history view does not shadow the browser History API', () => {
  assert.match(html, /async function activityHistory\(\)/);
  assert.match(html, /history:activityHistory/);
  assert.doesNotMatch(html, /async function history\(\)/);
});

test('shared design tokens include mobile grid and consistent keyboard focus', () => {
  const tokens = fs.readFileSync('assets/css/tokens.css', 'utf8');
  assert.match(tokens, /--gc-card-radius:/);
  assert.match(tokens, /--gc-focus-ring:/);
  assert.match(tokens, /button:focus-visible/);
  assert.match(tokens, /min\(120px,100%\)/);
  assert.match(tokens, /prefers-reduced-motion:reduce/);
});
