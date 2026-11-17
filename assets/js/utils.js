/* Gaycha Club shared utilities — dependency-free browser helpers. */
(function (global) {
  'use strict';
  const locks = new Map();
  const pendingRefresh = new Map();
  const memoryCache = new Map();

  const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({
    '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
  }[char]));
  const $ = id => document.getElementById(id);
  const msg = (message, isError) => {
    let display = String(message ?? '');
    if (isError && /failed to fetch|network|jwt|permission denied|row-level security|not allowed|\b500\b|\b400\b|duplicate key|rpc|supabase|timeout/i.test(display)) {
      const id = 'GC-' + Math.random().toString(36).slice(2, 8).toUpperCase();
      global.console?.error?.('[Gaycha Club][unclassified UI error][' + id + ']', display);
      display = safeErrorMessage(display) + ' Référence : ' + id;
    }
    return `<div class="note ${isError ? 'err' : ''}" role="${isError ? 'alert' : 'status'}">${esc(display)}</div>`;
  };

  function safeErrorMessage(error) {
    const raw = String(error?.message || error || '');
    if (/network|fetch|load failed|failed to fetch|timeout/i.test(raw)) return 'Connexion indisponible. Vérifie ta connexion puis réessaie.';
    if (/jwt|token|auth|permission|not allowed|row-level security/i.test(raw)) return 'Cette action nécessite une connexion ou une autorisation supplémentaire.';
    if (/duplicate|unique constraint/i.test(raw)) return 'Cette opération semble déjà avoir été effectuée.';
    return 'Une erreur est survenue. Réessaie dans quelques instants.';
  }

  function handleError(error, context, target) {
    const id = 'GC-' + Math.random().toString(36).slice(2, 8).toUpperCase();
    global.console?.error?.('[Gaycha Club][' + context + '][' + id + ']', error);
    const host = typeof target === 'string' ? $(target) : target;
    const html = msg(safeErrorMessage(error) + ' Référence : ' + id, true);
    if (host) host.innerHTML = html;
    return { id, message: safeErrorMessage(error) };
  }

  async function safeClick(handler, key = 'default') {
    if (locks.get(key)) return { skipped: true };
    locks.set(key, true); // lock synchronously, before the first await
    try {
      return await handler();
    } finally {
      global.setTimeout(() => locks.delete(key), 300);
    }
  }

  function debounce(fn, delay = 50) {
    let timer;
    return function (...args) {
      global.clearTimeout(timer);
      timer = global.setTimeout(() => fn.apply(this, args), delay);
    };
  }

  function paginate(items, page = 1, pageSize = 20) {
    const total = items.length;
    const pages = Math.max(1, Math.ceil(total / pageSize));
    const current = Math.min(Math.max(1, page), pages);
    return { items: items.slice((current - 1) * pageSize, current * pageSize), page: current, pages, total, pageSize };
  }

  async function staleWhileRevalidate(key, fetcher, options = {}) {
    const ttl = Math.max(0, Number(options.ttl) || 300000);
    const storageKey = 'gaycha-cache:' + key;
    let cached = memoryCache.get(key);
    if (!cached) {
      try { cached = JSON.parse(global.localStorage.getItem(storageKey) || 'null'); } catch (_) { cached = null; }
    }
    const now = Date.now();
    const fresh = cached && now - cached.savedAt < ttl;
    if (fresh) return cached.value;

    if (!pendingRefresh.has(key)) {
      const task = Promise.resolve().then(fetcher).then(value => {
        const entry = { savedAt: Date.now(), value };
        memoryCache.set(key, entry);
        try { global.localStorage.setItem(storageKey, JSON.stringify(entry)); } catch (_) {}
        return value;
      }).finally(() => pendingRefresh.delete(key));
      pendingRefresh.set(key, task);
    }
    const refresh = pendingRefresh.get(key);
    if (cached && options.allowStale !== false) {
      refresh.catch(error => global.console?.warn?.('[Gaycha cache][' + key + '] refresh failed', error));
      return cached.value;
    }
    return refresh;
  }

  function showState(target, title, detail) {
    const host = typeof target === 'string' ? $(target) : target;
    if (!host) return;
    host.innerHTML = '<section class="empty-state" role="status"><h2>' + esc(title) + '</h2>' + (detail ? '<p>' + esc(detail) + '</p>' : '') + '</section>';
  }

  const RN = {commun:['Commun','●'],peu_commun:['Peu commun','⬢'],rare:['Rare','◆'],epique:['Épique','★'],legendaire:['Légendaire','♛'],secrete:['Secrète','◈']};
  global.GaychaUtils = { esc, $, msg, RN, handleError, safeClick, debounce, paginate, staleWhileRevalidate, showState };
})(window);
