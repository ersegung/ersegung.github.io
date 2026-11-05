/* Progressive enhancement: all profiles remain readable without JavaScript. */
(() => {
  'use strict';
  const form = document.querySelector('#people-search-form');
  const input = document.querySelector('#people-search');
  const status = document.querySelector('#people-search-status');
  const reset = document.querySelector('#people-reset');
  const empty = document.querySelector('#people-empty');
  if (!form || !input || !status || !reset || !empty) return;
  const entries = Array.from(document.querySelectorAll('[data-person-entry]'));
  const sections = Array.from(document.querySelectorAll('[data-people-section]'));
  const subgroups = Array.from(document.querySelectorAll('[data-people-subgroup]'));
  const normalize = value => value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase();
  const searchable = entries.map(entry => ({entry, text: normalize(entry.textContent)}));
  function filter() {
    const terms = normalize(input.value.trim()).split(/\s+/).filter(Boolean);
    let count = 0;
    searchable.forEach(({entry, text}) => {
      const match = terms.every(term => text.includes(term));
      entry.hidden = !match;
      if (match) count += 1;
    });
    subgroups.forEach(group => {group.hidden = !Array.from(group.querySelectorAll('[data-person-entry]')).some(entry => !entry.hidden);});
    sections.forEach(section => {section.hidden = !Array.from(section.querySelectorAll('[data-person-entry]')).some(entry => !entry.hidden);});
    empty.hidden = count !== 0;
    status.textContent = terms.length ? `${count} matching ${count === 1 ? 'entry' : 'entries'}.` : 'Search by name, research topic, or degree.';
  }
  function clearSearch() { input.value = ''; filter(); }
  form.hidden = false;
  status.hidden = false;
  form.addEventListener('submit', event => event.preventDefault());
  input.addEventListener('input', filter);
  input.addEventListener('keydown', event => {
    if (event.key === 'Escape') {clearSearch(); input.focus();}
  });
  reset.addEventListener('click', () => {clearSearch();input.focus();});
  // Section links must work even when their targets are hidden by a search.
  document.querySelectorAll('.people-directory-nav a').forEach(link => {
    link.addEventListener('click', clearSearch);
  });
  // A degree-history link also works after filtering to a graduation year.
  document.querySelectorAll('[data-current-profile]').forEach(link => {
    link.addEventListener('click', clearSearch);
  });
  document.querySelectorAll('.person-avatar img').forEach(img => {
    img.addEventListener('error', () => {
      const wrapper = img.closest('.person-avatar');
      if (wrapper) {wrapper.textContent = wrapper.dataset.initials || ''; wrapper.setAttribute('aria-hidden', 'true');}
    });
  });
  filter();
})();
