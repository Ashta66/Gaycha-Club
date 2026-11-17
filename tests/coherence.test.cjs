const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const html = fs.readFileSync('index.html', 'utf8');
const en = JSON.parse(fs.readFileSync('i18n/en.json', 'utf8'));
const es = JSON.parse(fs.readFileSync('i18n/es.json', 'utf8'));
const achievementSql = fs.readFileSync('supabase/migrations/20261117213300_fix_achievement_sync_and_admin_stats.sql', 'utf8');
const readsSql = fs.readFileSync('supabase/migrations/20261117213257_reconcile_trade_offer_reads.sql', 'utf8');

test('translation dictionaries are complete and loaded from JSON', () => {
  assert.ok(Object.keys(en).length >= 240);
  assert.ok(Object.keys(es).length >= 240);
  assert.equal(en['Ma collection'], 'My collection');
  assert.equal(es['Ma collection'], 'Mi colección');
  assert.doesNotMatch(html, /UI_TRANSLATIONS/);
  assert.match(html, /GaychaI18n\?\.dictionaries\?\.\[currentLanguage\]/);
});

test('admin statistics distinguish booster opens and recent sign-ins', () => {
  assert.match(achievementSql, /'ouvertures_boosters'/);
  assert.match(achievementSql, /'connexions_30_jours'/);
  assert.match(achievementSql, /'top_cartes'/);
  assert.match(html, /Cartes les plus obtenues/);
  assert.match(html, /Ouvertures de boosters/);
});

test('legacy achievement RPC uses the named primary-key constraint', () => {
  assert.match(achievementSql, /ON CONFLICT ON CONSTRAINT user_achievements_pkey DO NOTHING/);
  assert.doesNotMatch(achievementSql, /ON CONFLICT \(user_id, achievement_key\)/);
});

test('trade read-marker migration is reproducible and participant-scoped', () => {
  assert.match(readsSql, /CREATE TABLE IF NOT EXISTS public\.trade_offer_reads/);
  assert.match(readsSql, /ENABLE ROW LEVEL SECURITY/);
  assert.match(readsSql, /user_id = \(SELECT auth\.uid\(\)\)/);
  assert.match(readsSql, /o\.proposer_id = \(SELECT auth\.uid\(\)\) OR o\.recipient_id = \(SELECT auth\.uid\(\)\)/);
});

test('image key management binds handlers only after its controls are rendered', () => {
  const render = html.indexOf('app.innerHTML=`<section class="admin-hero"');
  const handlers = html.indexOf("if(tab==='imagekeys'){", render);
  assert.ok(render >= 0 && handlers > render, 'image key handlers must be registered after admin HTML is inserted');
  assert.match(html, /id="imagekeys-save"/);
  assert.match(html, /id="imagekeys-status"/);
});

test('legal information is reachable from the global page footer', () => {
  for (const key of ['mentions', 'privacy', 'terms', 'moderation', 'cookies']) {
    assert.match(html, new RegExp('data-legal="' + key + '"'));
  }
  assert.match(html, /id="legal-dialog"/);
  assert.match(html, /const legalPages=/);
});
