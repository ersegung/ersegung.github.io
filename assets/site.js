const search = document.querySelector('#paper-search');
const topic = document.querySelector('#paper-topic');
if (search && topic) {
  document.querySelector('#paper-tools').hidden = false;
  const papers = [...document.querySelectorAll('.paper')];
  const groups = [...document.querySelectorAll('.year-section')];
  const status = document.querySelector('#paper-count');
  const empty = document.querySelector('#no-results');
  function filterPapers() {
    const query = search.value.trim().toLocaleLowerCase();
    let visible = 0;
    papers.forEach(paper => {
      const matchesText = paper.textContent.toLocaleLowerCase().includes(query);
      const matchesTopic = topic.value === 'all' || paper.dataset.topic === topic.value;
      paper.hidden = !(matchesText && matchesTopic);
      if (!paper.hidden) visible++;
    });
    groups.forEach(group => { group.hidden = ![...group.querySelectorAll('.paper')].some(paper => !paper.hidden); });
    status.textContent = `${visible} of ${papers.length} selected papers`;
    empty.hidden = visible !== 0;
  }
  search.addEventListener('input', filterPapers);
  topic.addEventListener('change', filterPapers);
  filterPapers();
}
document.querySelector('[data-print]')?.addEventListener('click', () => window.print());
