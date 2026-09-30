import * as store from '../store.js';
import { esc, fmtDate, confirmDialog, rangeText, icons, WEEKDAY_NAMES } from '../ui.js';
import { DAY_MS } from '../progression.js';
import { startSession } from './session.js';
import { showGuide } from '../guide.js';

const weekdayOf = (iso) => ((new Date(`${iso}T00:00:00Z`).getUTCDay() + 6) % 7) + 1; // 1 = lunes
const longDate = (iso) => fmtDate(iso, { weekday: 'long', day: 'numeric', month: 'long' });

// Semana de prueba: se entrena sin apuntar nada hasta block.startDate.
function trialCard(block, t) {
  const range = `${fmtDate(block.trialStart, { day: 'numeric' })}–${fmtDate(new Date(Date.parse(block.startDate) - DAY_MS).toISOString().slice(0, 10), { day: 'numeric', month: 'long' })}`;
  if (t < block.trialStart) {
    const n = Math.round((Date.parse(block.trialStart) - Date.parse(t)) / DAY_MS);
    return `<div class="card accent stack">
      <div class="eyebrow">Empiezas con la semana de prueba</div>
      <h2 style="font-size:1.4rem;margin:0">${esc(longDate(block.trialStart))}</h2>
      <p class="muted">Faltan ${n} ${n === 1 ? 'día' : 'días'}. La primera semana (${esc(range)}) entrenas los 4 días <strong>sin apuntar nada</strong>: sirve para aprender las máquinas, encontrar tu peso y ver si algún ejercicio te molesta. Empiezas a apuntar el ${esc(longDate(block.startDate))}.</p>
      <a class="btn btn-block" href="#/plan">Ver lo que toca</a>
      <a class="btn btn-ghost btn-block btn-sm" href="#/actividad">Ver calendario</a>
    </div>`;
  }
  const day = block.days.find((d) => d.weekday === weekdayOf(t));
  const nextDay = block.days.find((d) => d.weekday > weekdayOf(t));
  const how = `<div class="note primary small">En cada ejercicio: 1 serie de calentamiento muy ligera y <strong>2 series de 12–15</strong>. Busca un peso con el que las últimas repeticiones cuesten, con la técnica perfecta y dejando unas 3 en reserva. Si te sobran más, sube una placa; si no llegas a 12, baja una. Si algo molesta el brazo más de 3 sobre 10, déjalo y coméntalo.</div>`;
  return `<div class="card accent stack">
    <div><div class="eyebrow">Semana de prueba · no se apunta nada</div>
    ${day
      ? `<h2 style="font-size:1.4rem;margin:2px 0 0">Hoy: ${esc(day.name)}</h2><p class="muted" style="margin:0">${esc(day.subtitle)}</p>`
      : `<h2 style="font-size:1.4rem;margin:2px 0 0">Hoy descansas</h2>${nextDay ? `<p class="muted" style="margin:0">Próximo: ${esc(WEEKDAY_NAMES[nextDay.weekday].toLowerCase())}, ${esc(nextDay.name)}</p>` : ''}`}</div>
    ${day ? `${how}<ul class="list">${day.items.map((it) => `<li class="row spread"><span class="grow">${esc(store.exercises()[it.exerciseId]?.name ?? it.exerciseId)}<br><span class="small muted num">2 × ${'12–15'}${/zancadas/.test(it.exerciseId) ? ' pasos por pierna, sin peso' : ''}</span></span><button class="btn-sm btn-ghost" data-guide="${esc(it.exerciseId)}">${icons.info} Cómo se hace</button></li>`).join('')}</ul>` : ''}
    <p class="small muted" style="margin:0">El ${esc(longDate(block.startDate))} empieza la semana 1: desde ese día apuntas cada entreno y la app te irá diciendo qué peso usar.</p>
  </div>`;
}

export function render() {
  const st = store.get();
  const block = store.activeBlock();
  const active = st.activeSessionId && store.sessionById(st.activeSessionId);
  const next = store.nextSlot(block);
  const t = store.today();
  const started = st.sessions.some((s) => s.blockId === block.id);
  const daysLeft = block.startDate ? Math.round((Date.parse(block.startDate) - Date.parse(t)) / DAY_MS) : 0;

  let html = `<div class="eyebrow">${esc(fmtDate(t, { weekday: 'long', day: 'numeric', month: 'long' }))}</div>
    <h1>Hola${store.profile().name ? `, ${esc(store.profile().name)}` : ''}</h1>`;

  if (active) {
    const day = store.blockById(active.blockId)?.days.find((d) => d.id === active.dayId);
    html += `<div class="card accent stack">
      <div><div class="eyebrow">Entrenamiento a medias</div><h2>${esc(day?.name ?? '')} · ${esc(day?.subtitle ?? '')}</h2></div>
      <a class="btn btn-primary btn-block" href="#/sesion/${active.id}">Continuar</a>
    </div>`;
  } else if (!started && block.trialStart && t < block.startDate) {
    html += trialCard(block, t);
  } else if (!started && daysLeft > 0) {
    html += `<div class="card accent stack">
      <div class="eyebrow">Próximo entrenamiento</div>
      <h2 style="font-size:1.4rem;margin:0">${esc(fmtDate(block.startDate, { weekday: 'long', day: 'numeric', month: 'long' }))}</h2>
      <p class="muted">Faltan ${daysLeft} ${daysLeft === 1 ? 'día' : 'días'}. Hasta entonces, descansa y recupérate: no hace falta apuntar nada.</p>
      <a class="btn btn-block" href="#/plan">Ver lo que toca</a>
      <a class="btn btn-ghost btn-block btn-sm" href="#/actividad">Ver calendario</a>
    </div>
    <button class="btn-ghost btn-block btn-sm" data-start="${next.week}|${next.dayId}">Empezar antes</button>`;
  } else if (next) {
    const day = block.days.find((d) => d.id === next.dayId);
    html += `<div class="card accent stack">
      <div><div class="eyebrow">Hoy toca</div>
      <h2 style="font-size:1.4rem;margin:2px 0 0">${esc(day.name)}</h2>
      <p class="muted" style="margin:0">${esc(day.subtitle)}</p></div>
      <button class="btn-primary btn-block" data-start="${next.week}|${next.dayId}">Empezar</button>
    </div>`;
  } else {
    html += `<div class="card accent stack">
      <h2>¡${esc(block.name)} terminado! 🎉</h2>
      <p class="muted" style="margin:0">Mira cuánto has avanzado y qué significa antes de preparar el siguiente.</p>
      <a class="btn btn-primary btn-block" href="#/resumen/${block.id}">Ver tu resumen</a>
      <a class="btn btn-block" href="#/plan">Crear el siguiente bloque</a>
    </div>`;
  }

  if (started || daysLeft <= 0) {
    const week = active?.week ?? next?.week ?? block.weeks[block.weeks.length - 1];
    html += `<div class="card"><h2>Semana ${week}</h2>
      <div class="week-grid">${block.days.map((d) => {
        const s = store.sessionFor(block.id, week, d.id);
        const isNext = next && next.week === week && next.dayId === d.id && !active;
        return `<button class="day-pill ${s?.finished ? 'done' : ''} ${isNext ? 'next' : ''}" data-day="${week}|${d.id}">
          <strong>${esc(d.name)}</strong>${d.weekday ? `<span class="small faint">${WEEKDAY_NAMES[d.weekday].slice(0, 3)}</span>` : ''}<span class="small">${s?.finished ? '✓ hecho' : s ? 'a medias' : ''}</span>
        </button>`;
      }).join('')}</div></div>`;
  }

  const steps = st.steps.find((s) => s.date === t);
  html += `<div class="card"><h2>Apunta hoy</h2>
    <div class="row">
      <label class="field grow"><span>Pasos</span><input id="q-steps" type="number" inputmode="numeric" step="100" value="${steps?.steps ?? ''}"></label>
      <label class="field grow"><span>Cardio (min)</span><input id="q-cardio" type="number" inputmode="numeric" value="${steps?.cardioMin ?? ''}"></label>
    </div>
  </div>`;
  return html;
}

export function mount(root) {
  root.querySelectorAll('[data-guide]').forEach((b) => (b.onclick = () => showGuide(b.dataset.guide)));
  root.querySelectorAll('[data-start]').forEach((b) => (b.onclick = () => {
    const [w, d] = b.dataset.start.split('|');
    startSession(store.activeBlock().id, Number(w), d);
  }));
  root.querySelectorAll('[data-day]').forEach((b) => (b.onclick = async () => {
    const [w, d] = b.dataset.day.split('|');
    const block = store.activeBlock();
    const s = store.sessionFor(block.id, Number(w), d);
    if (s) return (location.hash = `#/sesion/${s.id}`);
    const day = block.days.find((x) => x.id === d);
    const msg = store.get().activeSessionId
      ? `Tienes otro entrenamiento a medias. ¿Empezar ${day.name} igualmente?`
      : `¿Empezar ${day.name}?`;
    if (await confirmDialog(msg, { ok: 'Empezar' })) startSession(block.id, Number(w), d);
  }));

  const t = store.today();
  const num = (el) => (el.value.trim() === '' ? null : Number(el.value.replace(',', '.')));
  const saveSteps = () => {
    const steps = num(root.querySelector('#q-steps'));
    const cardioMin = num(root.querySelector('#q-cardio'));
    store.update((st) => {
      st.steps = st.steps.filter((s) => s.date !== t);
      if (steps !== null || cardioMin !== null) st.steps.push({ date: t, steps, cardioMin });
    });
  };
  root.querySelector('#q-steps').onchange = saveSteps;
  root.querySelector('#q-cardio').onchange = saveSteps;
}
