(() => {
  const call = (name, ...args) => window.sketchup?.[name](...args);
  const labels = {
    ready: 'Готов',
    ready_with_warnings: 'Готов с предупреждениями',
    not_ready: 'Не готов'
  };

  window.MebelFlowReadiness = {
    render(report) {
      const status = document.getElementById('status');
      status.className = `status ${report.status}`;
      status.textContent = labels[report.status] || report.status;
      document.getElementById('summary').innerHTML = `Ошибки: <b>${report.summary.errors}</b> · Предупреждения: <b>${report.summary.warnings}</b> · Полигоны: <b>${report.asset_manifest.geometry.triangle_count}</b>`;
      const issues = document.getElementById('issues');
      issues.innerHTML = '';
      if (!report.issues.length) {
        issues.innerHTML = '<div class="empty">Блокирующих проблем и предупреждений не найдено.</div>';
        return;
      }
      report.issues.forEach(issue => {
        const card = document.createElement('article');
        card.className = `issue ${issue.severity}`;
        const buttons = issue.entity_ids.map(id => `<button data-id="${id}">#${id}</button>`).join('');
        card.innerHTML = `<h2>${escapeHtml(issue.code)}</h2><p>${escapeHtml(issue.message)}</p><div class="entities">${buttons}</div>`;
        card.addEventListener('click', event => {
          const id = event.target.dataset.id;
          if (id) call('highlight_readiness_entity', Number(id));
          else if (issue.entity_ids.length) call('highlight_readiness_issue', issue.entity_ids);
        });
        issues.appendChild(card);
      });
    }
  };

  document.addEventListener('DOMContentLoaded', () => call('readiness_ready'));
  function escapeHtml(value) { const div = document.createElement('div'); div.textContent = value; return div.innerHTML; }
})();
