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
  assert.match(html, /staleWhileRevalidate\('public-cards-v2'/);
  assert.match(html, /sb\.from\('cards'\)/);
  assert.doesNotMatch(html, /staleWhileRevalidate\('(profile|balance|inventory|trades|messages)/);
});

test('both card grids paginate to twenty entries', () => {
  assert.match(html, /paginate\(shown,collectionPage,20\)/);
  assert.match(html, /paginate\(shown,catalogPage,20\)/);
});

test('booster cards can be revealed individually with mouse or keyboard', () => {
  assert.match(html, /role='button' tabindex='0' aria-pressed='false'/);
  assert.match(html, /event\.key==='Enter'\|\|event\.key===' '/);
  assert.match(html, /el\.setAttribute\('aria-pressed','true'\)/);
  assert.match(html, /appuie sur une carte pour accélérer/);
});

test('booster reveal styling reflects the card rarity', () => {
  assert.match(html, /rarity-\"\+esc\(c\?\.rarity\|\|'unknown'\)/);
  assert.match(html, /fl\.rarity-legendaire/);
  assert.match(html, /fl\.rarity-secrete/);
});

test('collection binder shows series completion and card ownership in zoom', () => {
  assert.match(html, /collection-series-completion/);
  assert.match(html, /collectionCopies=cnt/);
  assert.match(html, /Dans ta collection/);
  assert.match(html, /cartes de cette série obtenues/);
});

test('missions page presents progression summaries and accessible filters', () => {
  assert.match(html, /Missions & récompenses/);
  assert.match(html, /mission-summary/);
  assert.match(html, /data-mission-filter="daily"/);
  assert.match(html, /data-mission-filter="weekly"/);
  assert.match(html, /data-mission-filter="ready"/);
  assert.match(html, /aria-pressed/);
});

test('mission rewards continue to use existing secure RPCs without schema changes', () => {
  assert.match(html, /sb\.rpc\('my_missions'\)/);
  assert.match(html, /sb\.rpc\('claim_mission',\{p_slug:button\.dataset\.m\}\)/);
  assert.match(html, /xp_reward/);
  assert.match(html, /mission-progress-copy/);
});


test('dashboard displays the existing XP total as a visual level progression', () => {
  assert.ok(html.includes("from('profiles').select('xp').eq('id',user.id)"));
  assert.ok(html.includes('Niveau ${level}'));
  assert.match(html, /dashboard-xp-track/);
  assert.match(html, /Gagner de l’XP/);
});

test('XP progression is presentation-only and retains existing achievement and mission sources', () => {
  assert.match(html, /sync_user_achievements/);
  assert.match(html, /xp_reward/);
  assert.doesNotMatch(html, /update\(\{[^}]*xp:/);
});
