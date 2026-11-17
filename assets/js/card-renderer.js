/* Reusable card renderer. Dependencies are injected by the host application. */
(function (global) {
  'use strict';
  function renderCard(c, n = 1, helpers = {}) {
    const { RN, esc, venueCardArt, cardIcon } = helpers;
    const rarity = RN[c.rarity] || RN.commun;
    const series = Array.isArray(c.series) ? (c.series[0] || {}) : (c.series || {});
    const venue = !c.is_fictional && (Array.isArray(c.venue_sources) ? c.venue_sources.length > 0 : !!c.venue_sources);
    return `<div class="card r-${esc(c.rarity)}" data-cid="${esc(c.id)}" tabindex="0" role="button" aria-label="Agrandir ${esc(c.name)}" style="--s1:${esc(series.color_a)};--s2:${esc(series.color_b)}"><span class="card-foil" aria-hidden="true"></span><div class="band"><span>${esc((series.name || '').toUpperCase())}</span><span>${rarity[1]} ${rarity[0].toUpperCase()}</span></div>${n > 1 ? `<span class="x">×${n}</span>` : ''}<div class="art">${c.image_path ? '<img src="' + esc(c.image_path) + '" alt="" loading="lazy" decoding="async" fetchpriority="low" referrerpolicy="no-referrer">' : venue ? venueCardArt(c) : `<div class="card-illustration" aria-hidden="true"><span>${cardIcon(c.name)}</span><i>GAYCHA CLUB</i></div>`}</div><div class="nm">${esc(c.name)}</div><div class="spec">${esc(c.spec)}</div><div class="meta"><span class="rar">${rarity[1]} ${rarity[0]}</span><span>N° ${String(c.number).padStart(3, '0')}</span></div></div>`;
  }
  document.addEventListener('error', function (event) {
    const image = event.target;
    if (!(image instanceof HTMLImageElement) || !image.matches('.art img')) return;
    image.style.display = 'none';
    image.removeAttribute('src');
    image.dataset.loadFailed = 'true';
  }, true);

  global.GaychaCardRenderer = { renderCard };
})(window);
