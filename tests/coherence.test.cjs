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


test('image assistant exposes a provider selector and guards missing controls', () => {
  assert.match(html, /id="ai-provider"/);
  for (const provider of ['openai', 'stability', 'google', 'replicate', 'fal', 'huggingface', 'bfl', 'ideogram', 'together']) {
    assert.match(html, new RegExp('value="' + provider + '"'));
  }
  assert.match(html, /if\(!providerSelect\)\{setStatus\(/);
  assert.match(html, /provider:providerSelect\.value\|\|'openai'/);
});

test('image quota reservations can be refunded after provider failures', () => {
  const quotaSql = fs.readFileSync('supabase/migrations/20261118000200_card_assistant_quota_refunds.sql', 'utf8');
  const edge = fs.readFileSync('supabase/functions/card-assistant/index.ts', 'utf8');
  assert.match(quotaSql, /reserve_card_assistant_quota/);
  assert.match(quotaSql, /release_card_assistant_quota/);
  assert.match(edge, /reserve_card_assistant_quota/);
  assert.match(edge, /release_card_assistant_quota/);
  assert.match(edge, /credit_balance_exhausted/);
  assert.match(edge, /content_moderation/);
});


test('image-provider admin RPCs require an existing admin profile', () => {
  const sql = fs.readFileSync('supabase/migrations/20261118000300_harden_image_provider_admin_guards.sql', 'utf8');
  assert.equal((sql.match(/if auth\\.uid\\(\\) is null then/g) || []).length, 2);
  assert.equal((sql.match(/if v_role is distinct from 'admin' then/g) || []).length, 2);
  assert.match(sql, /set search_path to ''/);
  assert.match(sql, /revoke all on function public\\.admin_store_image_provider_key\\(text,text\\) from public, anon/);
  assert.match(sql, /grant execute on function public\\.admin_store_image_provider_key\\(text,text\\) to authenticated/);
  assert.match(sql, /image_provider\\.store/);
  assert.doesNotMatch(sql, /p_api_key[^;]*log_audit/i);
});
