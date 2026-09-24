import * as store from './store.js';
import { icons, esc } from './ui.js';
import { resume as resumeRest } from './timer.js';
import * as home from './views/home.js';
import * as session from './views/session.js';
import * as plan from './views/plan.js';
import * as progress from './views/progress.js';
import * as body from './views/body.js';
import * as more from './views/more.js';

window.GOAZEN_VERSION = '1.2.0';

const routes = [
  { re: /^#?\/?$/, tab: 'home', render: home.render, mount: home.mount },
  { re: /^#\/sesion\/([\w-]+)$/, keys: ['id'], tab: 'home', render: session.render, mount: session.mount, unmount: session.unmount },
  { re: /^#\/plan$/, tab: 'plan', render: plan.render, mount: plan.mount },
  { re: /^#\/progreso$/, tab: 'progreso', render: progress.renderList },
  { re: /^#\/ejercicio\/([\w-]+)$/, keys: ['id'], tab: 'progreso', render: progress.renderDetail, mount: progress.mountDetail },
  { re: /^#\/(?:actividad|cuerpo)$/, tab: 'actividad', render: body.render, mount: body.mount },
  { re: /^#\/mas$/, tab: 'mas', render: more.render, mount: more.mount },
  { re: /^#\/ciencia$/, tab: 'mas', render: more.renderScience },
];

const TABS = [
  ['home', '#/', 'Hoy', icons.home],
  ['plan', '#/plan', 'Plan', icons.plan],
  ['progreso', '#/progreso', 'Progreso', icons.chart],
  ['actividad', '#/actividad', 'Actividad', icons.body],
  ['mas', '#/mas', 'Más', icons.more],
];

const main = document.querySelector('main');
const nav = document.querySelector('nav.tabs');
let current = null;

function route() {
  const hash = location.hash || '#/';
  for (const r of routes) {
    const m = hash.match(r.re);
    if (!m) continue;
    const params = Object.fromEntries((r.keys ?? []).map((k, i) => [k, decodeURIComponent(m[i + 1])]));
    return { r, params };
  }
  return { r: routes[0], params: {} };
}

function render({ keepScroll = false } = {}) {
  const next = route();
  // Al cambiar de pantalla (incluido el gesto "atrás") no deben quedar diálogos abiertos.
  if (!keepScroll) document.querySelectorAll('dialog[open]').forEach((d) => d.close());
  if (current && current.r !== next.r) current.r.unmount?.();
  const sameView = current && current.r === next.r && JSON.stringify(current.params) === JSON.stringify(next.params);
  current = next;
  const y = window.scrollY;
  try {
    main.innerHTML = next.r.render(next.params);
    next.r.mount?.(main, () => render({ keepScroll: true }), next.params);
  } catch (e) {
    console.error(e);
    main.innerHTML = `<div class="card"><h2>Algo ha fallado</h2><p class="muted small">${esc(e.message)}</p><a href="#/">Volver al inicio</a></div>`;
  }
  window.scrollTo(0, keepScroll || sameView ? y : 0);
  nav.innerHTML = TABS.map(([id, href, label, icon]) =>
    `<a href="${href}" class="${next.r.tab === id ? 'on' : ''}" ${next.r.tab === id ? 'aria-current="page"' : ''}>${icon}<span>${label}</span></a>`).join('');
  const err = store.lastSaveError();
  if (err) main.insertAdjacentHTML('afterbegin', `<div class="note warn" style="margin-bottom:12px">No se pudo guardar en el móvil (${esc(err.message)}). Descarga una copia de seguridad en Más.</div>`);
}

more.applyTheme();
window.addEventListener('hashchange', () => render());
render();
resumeRest();
store.requestPersistence();

if ('serviceWorker' in navigator && location.protocol !== 'file:') {
  navigator.serviceWorker.register('sw.js').catch((e) => console.warn('SW', e));
}
