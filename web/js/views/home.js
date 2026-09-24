import * as store from '../store.js';
import { esc, fmtDate, confirmDialog } from '../ui.js';
import { DAY_MS } from '../progression.js';
import { startSession } from './session.js';

export function render() {
  const st = store.get();
  const block = store.activeBlock();
  const active = st.activeSessionId && store.sessionById(st.activeSessionId);
  const next = store.nextSlot(block);
  const t = store.today();
  const started = st.sessions.some((s) => s.blockId === block.id);
  const daysLeft = block.startDate ? Math.round((Date.parse(block.startDate) - Date.parse(t)) / DAY_MS) : 0;

  let html = `<div class="eyebrow">${esc(fmtDate(t, { weekday: 'long', day: 'numeric', month: 'long' }))}</div>
    <h1>Hola, Ane</h1>`;

  if (active) {
    const day = store.blockById(active.blockId)?.days.find((d) => d.id === active.dayId);
    html += `<div class="card accent stack">
      <div><div class="eyebrow">Entrenamiento a medias</div><h2>${esc(day?.name ?? '')} · ${esc(day?.subtitle ?? '')}</h2></div>
      <a class="btn btn-primary btn-block" href="#/sesion/${active.id}">Continuar</a>
    </div>`;
  } else if (!started && daysLeft > 0) {
    html += `<div class="card accent stack">
      <div class="eyebrow">Próximo entrenamiento</div>
      <h2 style="font-size:1.4rem;margin:0">${esc(fmtDate(block.startDate, { weekday: 'long', day: 'numeric', month: 'long' }))}</h2>
      <p class="muted">Faltan ${daysLeft} ${daysLeft === 1 ? 'día' : 'días'}. Hasta entonces, descansa y recupérate: no hace falta apuntar nada.</p>
      <a class="btn btn-block" href="#/plan">Ver lo que toca</a>
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
      <a class="btn btn-primary btn-block" href="#/plan">Crear el siguiente bloque</a>
    </div>`;
  }

  if (started || daysLeft <= 0) {
    const week = active?.week ?? next?.week ?? block.weeks[block.weeks.length - 1];
    html += `<div class="card"><h2>Semana ${week}</h2>
      <div class="week-grid">${block.days.map((d) => {
        const s = store.sessionFor(block.id, week, d.id);
        const isNext = next && next.week === week && next.dayId === d.id && !active;
        return `<button class="day-pill ${s?.finished ? 'done' : ''} ${isNext ? 'next' : ''}" data-day="${week}|${d.id}">
          <strong>${esc(d.name)}</strong><span class="small">${s?.finished ? '✓ hecho' : s ? 'a medias' : ''}</span>
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
