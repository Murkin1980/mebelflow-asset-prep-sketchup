(() => {
  const state = { analysis: null, activeId: null };
  const roles = ['UNDEFINED','BODY','FACADE','DRAWER','HANDLE','APPLIANCE','GLASS','DECOR','INNER_SHADOW','IGNORE','DELETE_FROM_PREPARED_COPY'];
  const call = (name, ...args) => window.sketchup?.[name](...args);

  function render() {
    if (!state.analysis) return;
    document.getElementById('rootName').textContent = state.analysis.root_name;
    const items = document.getElementById('items');
    items.innerHTML = '';
    const undefinedCount = state.analysis.items.filter(i => i.role === 'UNDEFINED').length;
    document.getElementById('progressText').textContent = `${state.analysis.items.length} элементов · неопределено ${undefinedCount}`;

    state.analysis.items.forEach(item => {
      const el = document.createElement('article');
      el.className = `item ${item.role === 'UNDEFINED' ? 'undefined' : 'confirmed'} ${state.activeId === item.id ? 'active' : ''}`;
      el.dataset.id = item.id;
      const options = roles.map(role => `<option value="${role}" ${role === item.role ? 'selected' : ''}>${role}</option>`).join('');
      el.innerHTML = `<div class="item-head"><span class="name">${escapeHtml(item.name)}</span><span>#${item.id}</span></div>
        <div class="meta">${item.type} · ${item.dimensions_mm.width} × ${item.dimensions_mm.depth} × ${item.dimensions_mm.height} мм</div>
        <div class="actions"><select>${options}</select><button data-action="focus">Фокус</button><button data-action="isolate">Изолировать</button></div>`;
      el.addEventListener('click', e => {
        if (e.target.tagName === 'SELECT' || e.target.tagName === 'BUTTON') return;
        state.activeId = item.id; call('select_entity', item.id); render();
      });
      el.querySelector('select').addEventListener('change', e => call('assign_role', item.id, e.target.value));
      el.querySelector('[data-action="focus"]').addEventListener('click', () => call('focus_entity', item.id));
      el.querySelector('[data-action="isolate"]').addEventListener('click', () => call('isolate_entity', item.id));
      items.appendChild(el);
    });
  }

  function selectNextUndefined() {
    if (!state.analysis) return;
    const list = state.analysis.items.filter(i => i.role === 'UNDEFINED');
    if (!list.length) return;
    const index = list.findIndex(i => i.id === state.activeId);
    const next = list[(index + 1) % list.length];
    state.activeId = next.id; call('focus_entity', next.id); render();
    document.querySelector(`[data-id="${next.id}"]`)?.scrollIntoView({block:'center'});
  }

  window.MebelFlow = {
    receive(name, payload) {
      if (name === 'analysis') state.analysis = payload;
      if (name === 'scene_selection') state.activeId = payload.id;
      if (name === 'role_updated') {
        const item = state.analysis?.items.find(i => i.id === payload.id);
        if (item) item.role = payload.role;
      }
      render();
    }
  };

  document.getElementById('showContext').addEventListener('click', () => call('show_context'));
  document.getElementById('nextUndefined').addEventListener('click', selectNextUndefined);
  document.addEventListener('DOMContentLoaded', () => call('ready'));

  function escapeHtml(value) { const div = document.createElement('div'); div.textContent = value; return div.innerHTML; }
})();
