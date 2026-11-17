const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const source = fs.readFileSync('assets/js/card-renderer.js', 'utf8');
const context = { window: {}, String };
vm.runInNewContext(source, context);
const render = context.window.GaychaCardRenderer.renderCard;
const helpers = {
  RN: { commun: ['Commun', '●'], rare: ['Rare', '◆'] },
  esc: value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),
  venueCardArt: () => '<div class="venue"></div>',
  cardIcon: () => '✦'
};

test('renders a safe accessible card and escapes user content', () => {
  const html = render({id:'1',name:'<script>',rarity:'commun',number:7,spec:'Test',series:{name:'Club',color_a:'#111',color_b:'#222'}}, 1, helpers);
  assert.match(html, /role="button"/);
  assert.match(html, /&lt;script&gt;/);
  assert.match(html, /N° 007/);
});

test('shows duplicate count and falls back to common rarity', () => {
  const html = render({id:'2',name:'Test',rarity:'unknown',number:1,spec:'',series:{}}, 3, helpers);
  assert.match(html, /×3/);
  assert.match(html, /Commun/);
});

test('uses lazy image loading when artwork exists', () => {
  const html = render({id:'3',name:'Photo',rarity:'rare',number:2,spec:'',image_path:'https://example.test/card.webp',series:{}}, 1, helpers);
  assert.match(html, /loading="lazy"/);
  assert.match(html, /decoding="async"/);
});

test('rarity ranking follows the six configured levels', () => {
  const utilsSource = fs.readFileSync('assets/js/utils.js', 'utf8');
  const utilsContext = { window: {}, String, Map, Math, console, setTimeout, clearTimeout };
  vm.runInNewContext(utilsSource, utilsContext);
  const rank = utilsContext.window.GaychaUtils.rarityRank;
  assert.equal(rank('commun'), 0);
  assert.equal(rank('rare'), 2);
  assert.equal(rank('secrete'), 5);
  assert.equal(rank('unknown'), -1);
});

test('pagination caps the rendered collection at twenty items', () => {
  const utilsSource = fs.readFileSync('assets/js/utils.js', 'utf8');
  const utilsContext = { window: {}, String, Map, Math, console, setTimeout, clearTimeout };
  vm.runInNewContext(utilsSource, utilsContext);
  const result = utilsContext.window.GaychaUtils.paginate(Array.from({length: 47}, (_, i) => i), 2, 20);
  assert.equal(result.items.length, 20);
  assert.equal(result.items[0], 20);
  assert.equal(result.pages, 3);
  assert.equal(result.total, 47);
});
