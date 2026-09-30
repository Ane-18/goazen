// Primera vez en un móvil: elegir perfil. Solo aparece si el móvil no tiene datos guardados.
import * as store from '../store.js';
import { PLAN_BLOQUE1 } from '../data/plan-bloque1.js';
import { esc, fmtDate, toast, confirmDialog } from '../ui.js';
import { importBackup } from '../export.js';

export function render() {
  const start = fmtDate(PLAN_BLOQUE1.startDate, { weekday: 'long', day: 'numeric', month: 'long' });
  return `<div class="welcome stack">
    <div>
      <div class="eyebrow">Goazen</div>
      <h1 style="margin-bottom:4px">¡Hola!</h1>
      <p class="muted">Tu cuaderno de gimnasio. Todo se guarda en este móvil. ¿Quién va a usar la app?</p>
    </div>

    <form class="card accent stack" data-new>
      <div>
        <h2 style="margin:0">Empiezo mi plan</h2>
        <p class="small muted" style="margin:4px 0 0">${esc(PLAN_BLOQUE1.name)}: 4 días a la semana en máquinas, desde el ${esc(start)}.</p>
      </div>
      <label class="field"><span>¿Cómo te llamas?</span><input name="name" autocomplete="given-name" required maxlength="30" placeholder="Tu nombre"></label>
      <button class="btn-primary btn-block" type="submit">Empezar</button>
    </form>

    <div class="card stack">
      <div>
        <h2 style="margin:0">Soy Ane</h2>
        <p class="small muted" style="margin:4px 0 0">Mi historial de las semanas 1–8 y el Bloque 3.</p>
      </div>
      <button class="btn-block" data-ane>Soy Ane</button>
    </div>

    <label class="btn btn-ghost btn-block btn-sm">Tengo una copia de seguridad<input type="file" accept="application/json,.json" class="hidden" data-restore></label>
  </div>`;
}

export function mount(root, rerender) {
  root.querySelector('[data-new]').onsubmit = (e) => {
    e.preventDefault();
    const name = e.target.name.value.trim();
    if (!name) return;
    store.createProfile('nuevo', name);
    location.hash = '#/';
    rerender();
  };
  root.querySelector('[data-ane]').onclick = async () => {
    if (!(await confirmDialog('Se cargará el historial y el plan de Ane en este móvil.', { ok: 'Soy Ane' }))) return;
    store.createProfile('ane');
    location.hash = '#/';
    rerender();
  };
  root.querySelector('[data-restore]').onchange = async (e) => {
    const f = e.target.files[0];
    if (!f) return;
    try { await importBackup(f); toast('Copia restaurada'); location.hash = '#/'; rerender(); } catch (err) { toast(err.message); }
  };
}
