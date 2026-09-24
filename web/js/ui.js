// Utilidades de interfaz compartidas por las vistas.
import { MUSCLES } from './data/exercises.js';

export const esc = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

export const muscleName = (m) => MUSCLES[m] ?? m;

export function fmtDate(iso, opts = { weekday: 'short', day: 'numeric', month: 'short' }) {
  if (!iso) return '';
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('es-ES', opts);
}

export function rangeText([a, b]) {
  return a === b ? `${a}` : `${a}–${b}`;
}

let toastTimer;
export function toast(msg, ms = 2600) {
  document.querySelector('.toast')?.remove();
  const el = document.createElement('div');
  el.className = 'toast';
  el.setAttribute('role', 'status');
  el.textContent = msg;
  document.body.appendChild(el);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.remove(), ms);
}

// Diálogo modal. `build(dlg, close)` rellena y conecta eventos. Devuelve una promesa
// que se resuelve con el valor pasado a close().
export function modal(html, build) {
  return new Promise((resolve) => {
    const dlg = document.createElement('dialog');
    dlg.innerHTML = `<div class="dlg">${html}</div>`;
    document.body.appendChild(dlg);
    let value;
    const close = (v) => { value = v; dlg.close(); };
    dlg.addEventListener('close', () => { dlg.remove(); resolve(value); });
    dlg.addEventListener('click', (e) => { if (e.target === dlg) close(); });
    build?.(dlg, close);
    dlg.showModal();
  });
}

export function confirmDialog(text, { ok = 'Aceptar', danger = false } = {}) {
  return modal(
    `<p>${esc(text)}</p>
     <div class="row" style="justify-content:flex-end">
       <button class="btn-ghost" data-v="0">Cancelar</button>
       <button class="${danger ? 'btn-danger' : 'btn-primary'}" data-v="1">${esc(ok)}</button>
     </div>`,
    (dlg, close) => dlg.querySelectorAll('[data-v]').forEach((b) => b.addEventListener('click', () => close(b.dataset.v === '1'))),
  );
}

const svg = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;

export const icons = {
  home: svg('<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>'),
  plan: svg('<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M8 9h8M8 13h8M8 17h5"/>'),
  chart: svg('<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>'),
  body: svg('<path d="M3 12h4l3-7 4 14 3-7h4"/>'),
  more: svg('<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>'),
  check: svg('<path d="M5 12l5 5L20 7"/>'),
  plus: svg('<path d="M12 5v14M5 12h14"/>'),
  swap: svg('<path d="M7 7h11l-3-3M17 17H6l3 3"/>'),
  edit: svg('<path d="M4 20h4L19 9l-4-4L4 16z"/>'),
  back: svg('<path d="M15 18l-6-6 6-6"/>'),
  x: svg('<path d="M6 6l12 12M18 6L6 18"/>'),
  up: svg('<path d="M12 19V5M6 11l6-6 6 6"/>'),
  down: svg('<path d="M12 5v14M6 13l6 6 6-6"/>'),
  alert: svg('<path d="M12 3l10 18H2z"/><path d="M12 10v4M12 17.5v.5"/>'),
};

// Sensaciones que se pueden marcar en un ejercicio (útiles para decidir sustituciones).
export const FLAGS = {
  molestia: 'Molestia / dolor',
  no_siento: 'No siento el músculo',
  nausea: 'Mareo / náusea',
  tecnica: 'Técnica a revisar',
};
