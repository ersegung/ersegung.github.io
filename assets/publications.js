(() => {
  const page = document.querySelector('[data-publication-page]');
  if (!page) return;

  const search = page.querySelector('#publication-search');
  const topic = page.querySelector('#publication-topic');
  const type = page.querySelector('#publication-type');
  const count = page.querySelector('#publication-count');
  const empty = page.querySelector('#no-results');
  const normalize = value => value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const papers = [...page.querySelectorAll('.paper')].map(element => ({
    element,
    text: normalize(element.textContent),
    topics: element.dataset.topic.split(/\s+/),
    type: element.dataset.type
  }));
  const years = [...page.querySelectorAll('.year-section')];
  const plural = (n, singular, pluralForm = singular + 's') => `${n} ${n === 1 ? singular : pluralForm}`;

  function filter() {
    const words = normalize(search.value.trim()).split(/\s+/).filter(Boolean);
    const totals = { journal: 0, conference: 0, preprint: 0 };
    for (const paper of papers) {
      const matches = words.every(word => paper.text.includes(word))
        && (topic.value === 'all' || paper.topics.includes(topic.value))
        && (!type || type.value === 'all' || paper.type === type.value);
      paper.element.hidden = !matches;
      if (matches) totals[paper.type]++;
    }
    for (const year of years) year.hidden = !year.querySelector('.paper:not([hidden])');
    const total = Object.values(totals).reduce((sum, value) => sum + value, 0);
    const parts = [plural(total, 'publication')];
    if (totals.journal) parts.push(plural(totals.journal, 'journal article'));
    if (totals.conference) parts.push(plural(totals.conference, 'conference contribution'));
    if (totals.preprint) parts.push(plural(totals.preprint, 'preprint'));
    count.textContent = parts.join(' · ');
    empty.hidden = total !== 0;
  }

  search.addEventListener('input', filter);
  topic.addEventListener('change', filter);
  type?.addEventListener('change', filter);
  page.querySelector('#reset-filters').addEventListener('click', () => {
    search.value = '';
    topic.value = 'all';
    if (type) type.value = 'all';
    filter();
    search.focus();
  });
  page.querySelector('#publication-tools').hidden = false;
  filter();
})();
