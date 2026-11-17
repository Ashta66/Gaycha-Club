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
