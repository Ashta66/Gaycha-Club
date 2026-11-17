/* Lightweight JSON translation loader; existing interface translations remain backward-compatible. */
(function (global) {
  'use strict';
  const supported = ['fr', 'en', 'es'];
  const dictionaries = { fr: {}, en: {}, es: {} };
  async function load() {
    await Promise.all(supported.map(async language => {
      try {
        const response = await fetch('./i18n/' + language + '.json', { cache: 'no-cache' });
        if (response.ok) dictionaries[language] = await response.json();
      } catch (error) {
        global.console?.warn?.('[Gaycha i18n] ' + language + ' dictionary unavailable', error);
      }
    }));
    global.dispatchEvent(new CustomEvent('gaycha:i18n-ready'));
    return dictionaries;
  }
  global.GaychaI18n = { supported, dictionaries, load };
  load();
})(window);
