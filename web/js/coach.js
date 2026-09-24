// Une el estado guardado con la lógica pura de progression.js.
import * as store from './store.js';
import { exerciseHistory, suggest, isStalled, workingSets, fmt, plannedVolume } from './progression.js';
import { esc, modal, muscleName, rangeText } from './ui.js';
import { MUSCLES } from './data/exercises.js';

export function historyOf(exerciseId) {
  return exerciseHistory(store.get().sessions, exerciseId);
}

export function isLoadless(ex) {
  return ex && ['banda', 'corporal'].includes(ex.equip);
}

export function suggestionFor(exerciseId, range, block = store.activeBlock()) {
  const ex = store.exercises()[exerciseId];
  return suggest({
    history: historyOf(exerciseId),
    range,
    rir: block?.rir ?? [1, 2],
    inc: ex?.inc ?? 2.5,
    today: store.today(),
    loadless: isLoadless(ex),
  });
}

// Estancamiento solo si sigues en el mismo rango de reps (un cambio de rango ya es un cambio de estímulo).
export function stallFor(exerciseId, range) {
  const h = historyOf(exerciseId);
  if (!h.length) return false;
  if (range && h[0].range && Math.abs(h[0].range[0] - range[0]) >= 2) return false;
  return isStalled(h);
}

export function lastText(h) {
  if (!h) return '';
  const sets = workingSets(h.entry);
  const byKg = new Map();
  for (const s of sets) {
    const k = `${fmt(s.kg)}`;
    if (!byKg.has(k)) byKg.set(k, []);
    byKg.get(k).push(s);
  }
  return [...byKg.entries()]
    .map(([kg, ss]) => `${kg !== '0' ? kg + ' kg × ' : ''}${ss.map((s) => s.reps).join(', ')}${ss.some((s) => Number.isFinite(s.rir)) ? ` · RIR ${ss.map((s) => (Number.isFinite(s.rir) ? fmt(s.rir) : '–')).join(', ')}` : ''}`)
    .join(' | ');
}

export function blockVolume(block = store.activeBlock()) {
  return plannedVolume(block, store.exercises());
}

export const STALL_TIPS =
  'Antes de cambiarlo revisa sueño, comida y técnica. Si sigue igual, prueba otra variante que trabaje el mismo músculo con un perfil distinto (máquina, polea o ángulo) y anota el motivo.';

// Selector de ejercicios. Devuelve el id elegido (o null).
export function pickExercise({ title = 'Elegir ejercicio', preferMuscles = [], exclude = [] } = {}) {
  const all = Object.values(store.exercises()).filter((e) => !exclude.includes(e.id));
  const score = (e) => (e.muscles.p.some((m) => preferMuscles.includes(m)) ? 0 : e.muscles.s.some((m) => preferMuscles.includes(m)) ? 1 : 2);
  all.sort((a, b) => score(a) - score(b) || a.name.localeCompare(b.name, 'es'));

  const item = (e) => `
    <li><button class="btn-block" style="justify-content:flex-start;text-align:left;background:transparent;padding:8px 0" data-id="${e.id}">
      <span class="grow"><span>${esc(e.name)}</span><br><span class="small faint">${e.muscles.p.map(muscleName).join(', ')}${e.muscles.s.length ? ' · ' + e.muscles.s.map(muscleName).join(', ') : ''}</span></span>
    </button></li>`;

  return modal(
    `<div class="row spread"><h2 style="margin:0">${esc(title)}</h2><button class="btn-ghost icon-btn" data-close aria-label="Cerrar">✕</button></div>
     <input type="search" placeholder="Buscar…" aria-label="Buscar ejercicio">
     <div class="dlg-scroll"><ul class="list">${all.map(item).join('')}</ul></div>
     <button class="btn-sm" data-new>+ Crear ejercicio nuevo</button>`,
    (dlg, close) => {
      dlg.querySelector('[data-close]').onclick = () => close(null);
      const input = dlg.querySelector('input');
      input.addEventListener('input', () => {
        const q = input.value.trim().toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
        dlg.querySelectorAll('[data-id]').forEach((b) => {
          const t = b.textContent.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
          b.closest('li').classList.toggle('hidden', q && !t.includes(q));
        });
      });
      dlg.querySelectorAll('[data-id]').forEach((b) => (b.onclick = () => close(b.dataset.id)));
      dlg.querySelector('[data-new]').onclick = async () => {
        const id = await createExercise(input.value, preferMuscles[0]);
        close(id ?? null);
      };
    },
  );
}

export function createExercise(name = '', muscle = 'gluteo') {
  const opts = Object.entries(MUSCLES).map(([k, v]) => `<option value="${k}" ${k === muscle ? 'selected' : ''}>${v}</option>`).join('');
  return modal(
    `<h2>Nuevo ejercicio</h2>
     <label class="field"><span>Nombre</span><input name="name" value="${esc(name)}" required></label>
     <label class="field"><span>Material</span><select name="equip">
       <option value="maquina">Máquina</option><option value="polea">Polea</option><option value="mancuerna">Mancuernas</option>
       <option value="barra">Barra</option><option value="banda">Banda</option><option value="corporal">Peso corporal</option></select></label>
     <label class="field"><span>Músculo principal</span><select name="p">${opts}</select></label>
     <label class="field"><span>Músculo secundario (opcional)</span><select name="s"><option value="">—</option>${opts.replace(' selected', '')}</select></label>
     <label class="field"><span>Incremento de carga (kg)</span><input name="inc" type="number" step="0.5" min="0" value="2.5" inputmode="decimal"></label>
     <div class="row" style="justify-content:flex-end"><button class="btn-ghost" data-c>Cancelar</button><button class="btn-primary" data-ok>Crear</button></div>`,
    (dlg, close) => {
      dlg.querySelector('[data-c]').onclick = () => close(null);
      dlg.querySelector('[data-ok]').onclick = () => {
        const f = (n) => dlg.querySelector(`[name=${n}]`).value;
        if (!f('name').trim()) return dlg.querySelector('[name=name]').focus();
        const id = 'custom_' + store.uid();
        store.update((st) => st.customExercises.push({
          id, name: f('name').trim(), equip: f('equip'),
          muscles: { p: [f('p')], s: f('s') ? [f('s')] : [] },
          inc: Number(f('inc')) || 0, compound: false, cue: '', custom: true,
        }));
        close(id);
      };
    },
  );
}

export function weekRangeNote(block, week) {
  const ranges = new Set();
  for (const d of block.days) for (const it of d.items) if (it.reps[week]) ranges.add(rangeText(it.reps[week]));
  return [...ranges].join(' · ');
}
