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

test('collection and catalogue grids use their intended page sizes', () => {
  assert.match(html, /paginate\(shown,collectionPage,20\)/);
  assert.match(html, /paginate\(shown,catalogPage,36\)/);
});

test('booster cards can be revealed individually with mouse or keyboard', () => {
  assert.match(html, /role='button' tabindex='0' aria-pressed='false'/);
  assert.match(html, /event\.key==='Enter'\|\|event\.key===' '/);
  assert.match(html, /el\.setAttribute\('aria-pressed','true'\)/);
  assert.match(html, /Clique sur une carte pour la retourner/);
  assert.match(html, /Tout retourner/);
  assert.match(html, /Les cartes restent cachées/);
  assert.doesNotMatch(html, /450\+i\*650/);
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

test('XP progression is presentation-only and the dashboard uses progressive badges without the legacy achievement RPC', () => {
  assert.doesNotMatch(html, /sync_user_achievements/);
  assert.match(html, /badgeSeries/);
  assert.match(html, /xp_reward/);
  assert.doesNotMatch(html, /update\(\{[^}]*xp:/);
});


test('admin catalogue exposes multi-variant AI artwork generation and selection', () => {
  assert.match(html, /id="cimg-generate"/);
  assert.match(html, /id="cimg-gallery"/);
  assert.match(html, /data-image-choice/);
  assert.match(html, /functions\.invoke\('card-assistant'/);
});

test('AI assistant existing-card edit actions are wired to a working selection flow', () => {
  assert.match(html, /data-ai-edit-card/);
  assert.match(html, /\$\('ai-generate'\)\.onclick/);
  assert.match(html, /\$\('ai-illustrate'\)\.onclick/);
});

test("collection favorite sits outside the card frame and assistant cards cannot overflow",()=>{assert.match(html,/collection-card-item\{position:relative;padding-top:22px/);assert.match(html,/collection-card-visual\{position:static!important/);assert.match(html,/ai-existing-meta>\*\{min-width:0;max-width:100%;overflow-wrap:anywhere/);assert.match(html,/id="ai-provider-save"/)});
test("image providers are selectable and Edge errors expose the server detail",()=>{for(const provider of ["openai","stability","google","replicate","fal","huggingface","bfl","ideogram","together"])assert.match(html,new RegExp('value="'+provider+'"'));assert.match(html,/context\.clone\(\)\.text\(\)/);});

test("admin booster editor previews presentation and syncs rarity sliders",()=>{assert.match(html,/admin-booster-visual-editor/);assert.match(html,/data-booster-range/);assert.match(html,/admin_set_booster_presentation/);assert.match(html,/boosterPresentationAttrs/)});

test("admin player detail panel is visual and exposes inventory and credit history through a secure RPC",()=>{assert.match(html,/data-account-details/);assert.match(html,/admin_get_account_detail/);assert.match(html,/admin-account-owned-grid/);assert.match(html,/admin-account-history/)});

test("admin mission editor has templates and a live reward/progression preview",()=>{assert.match(html,/data-mission-template/);assert.match(html,/mission-preview-steps/);assert.match(html,/mission-preview-rewards/)});
test("events page provides quick templates and a navigable monthly calendar",()=>{assert.match(html,/data-event-template/);assert.match(html,/events-calendar/);assert.match(html,/data-calendar-next/)});

test("admin dashboard has selectable periods, activity charts, alerts and recent audit",()=>{assert.match(html,/data-dashboard-days/);assert.match(html,/admin-dashboard-chart/);assert.match(html,/admin-dashboard-alerts/);assert.match(html,/admin-dashboard-audit/);assert.match(html,/admin_dashboard_detail/)});
