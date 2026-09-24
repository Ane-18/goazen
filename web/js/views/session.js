import * as store from '../store.js';
import { esc, fmtDate, muscleName, rangeText, icons, toast, modal, confirmDialog, FLAGS } from '../ui.js';
import { suggestionFor, stallFor, historyOf, lastText, pickExercise, isLoadless, STALL_TIPS } from '../coach.js';
import { fmt, bestSet, workingSets } from '../progression.js';
import { startRest, stop as stopRest } from '../timer.js';

const expanded = new Map(); // sessionId → Set de índices abiertos
let wakeLock = null;

export function startSession(blockId, week, dayId) {
  const block = store.blockById(blockId);
  const day = block.days.find((d) => d.id === dayId);
  const id = store.uid();
  store.update((st) => {
    st.sessions.push({
      id,
      blockId,
      week,
      dayId,
      date: store.today(),
      startedAt: new Date().toISOString(),
      finished: false,
      note: '',
      entries: day.items.map((it) => newEntry(it.exerciseId, it.reps[week] ?? Object.values(it.reps)[0], it.sets, it.optional, block)),
    });
    st.activeSessionId = id;
  });
  location.hash = `#/sesion/${id}`;
}

function newEntry(exerciseId, range, setsPlan, optional = false, block) {
  const sug = suggestionFor(exerciseId, range, block);
  return {
    exerciseId,
    range,
    setsPlan,
    optional,
    note: '',
    flags: [],
    sets: Array.from({ length: setsPlan[0] }, () => ({ kg: sug.kg ?? null, reps: null, rir: null, done: false })),
  };
}

export function render({ id }) {
  const s = store.sessionById(id);
  if (!s) return `<p>Entrenamiento no encontrado.</p><a href="#/">Volver</a>`;
  const block = store.blockById(s.blockId);
  const day = block?.days.find((d) => d.id === s.dayId);
  if (!expanded.has(id)) {
    const first = s.entries.findIndex((e) => !isComplete(e));
    expanded.set(id, new Set(s.finished ? [] : [first === -1 ? 0 : first]));
  }

  return `
    <div class="row spread">
      <a href="#/" class="btn btn-ghost icon-btn" aria-label="Volver">${icons.back}</a>
      ${s.finished ? '' : `<button class="btn-primary btn-sm" data-finish>Terminar</button>`}
    </div>
    <h1 style="margin-bottom:0">${esc(day?.name ?? '')}</h1>
    <p class="muted">${esc(day?.subtitle ?? '')}${s.finished ? ` · ${esc(fmtDate(s.date))}` : ''}</p>
    <div id="entries">${s.entries.map((e, i) => entryCard(s, e, i)).join('')}</div>
    <div class="stack" style="margin-top:16px">
      ${s.finished ? '' : `<button class="btn-primary btn-block" data-finish>Terminar entrenamiento</button>`}
      <details>
        <summary>Más opciones</summary>
        <div class="stack" style="margin-top:10px">
          <button class="btn-block btn-sm" data-add-ex>${icons.plus} Añadir un ejercicio solo hoy</button>
          <label class="field"><span>Notas del día</span><textarea data-session-note placeholder="Sueño, energía…">${esc(s.note)}</textarea></label>
          <button class="btn-danger btn-block btn-sm" data-discard>${s.finished ? 'Borrar este entrenamiento' : 'Descartar entrenamiento'}</button>
        </div>
      </details>
    </div>`;
}

function isComplete(e) {
  return e.sets.length > 0 && e.sets.every((x) => x.done);
}

function entryCard(s, e, i) {
  const ex = store.exercises()[e.exerciseId] ?? { name: e.exerciseId, muscles: { p: [], s: [] }, equip: '' };
  const open = expanded.get(s.id)?.has(i);
  const block = store.blockById(s.blockId);
  const item = block?.days.find((d) => d.id === s.dayId)?.items.find((it) => it.exerciseId === e.exerciseId);
  const last = historyOf(e.exerciseId).filter((h) => h.session.id !== s.id)[0];
  const sug = s.finished ? null : suggestionFor(e.exerciseId, e.range, block);
  const stalled = !s.finished && stallFor(e.exerciseId, e.range);
  const loadless = isLoadless(ex);
  const nSets = e.setsPlan ? rangeText(e.setsPlan) : e.sets.length;

  const target = sug?.kg != null && !loadless
    ? `<strong>${fmt(sug.kg)} kg</strong> · ${rangeText(e.range)} reps`
    : `${nSets} × ${rangeText(e.range)} reps`;

  const why = [
    sug?.text,
    stalled ? `Llevas 3 sesiones sin mejorar. ${STALL_TIPS}` : '',
    ex.cue ? `Técnica: ${ex.cue}` : '',
    item?.note ?? '',
    ex.equip === 'mancuerna' ? 'El peso es de cada mancuerna.' : '',
  ].filter(Boolean);

  const setRows = e.sets.map((set, j) => `
    <div class="set-row ${set.done ? 'done' : ''}" data-set="${j}">
      <span class="n">${j + 1}</span>
      <input data-f="kg" type="number" inputmode="decimal" step="0.1" min="0" value="${set.kg ?? ''}" placeholder="${loadless ? '—' : 'kg'}" aria-label="Peso serie ${j + 1}">
      <input data-f="reps" type="number" inputmode="numeric" min="0" value="${set.reps ?? ''}" placeholder="${rangeText(e.range)}" aria-label="Repeticiones serie ${j + 1}">
      <select data-f="rir" aria-label="RIR serie ${j + 1}">
        <option value="">–</option>
        ${[0, 1, 2, 3, 4].map((v) => `<option value="${v}" ${set.rir === v ? 'selected' : ''}>${v === 4 ? '4+' : v}</option>`).join('')}
      </select>
      <button class="check" data-check aria-label="${set.done ? 'Desmarcar' : 'Hecha'} serie ${j + 1}">${icons.check}</button>
    </div>`).join('');

  return `
  <div class="card ex-card ${open ? '' : 'collapsed'} ${isComplete(e) ? 'complete' : ''}" data-entry="${i}" style="margin-top:12px">
    <div class="ex-head" data-toggle>
      <span class="idx">${isComplete(e) ? '✓' : i + 1}</span>
      <div class="grow">
        <h3>${esc(ex.name)}${e.optional ? ' <span class="chip">opcional</span>' : ''}</h3>
        <div class="small muted">${s.finished ? `${workingSets(e).length} series` : target}</div>
      </div>
    </div>
    <div class="ex-body">
      ${sug ? `<p class="small" style="color:var(--primary-ink);font-weight:600;margin-bottom:4px">${esc(sug.short)}</p>` : ''}
      ${last ? `<p class="small muted">Última vez: ${esc(lastText(last))}</p>` : ''}
      <div class="sets">
        <div class="set-head"><span></span><span>kg</span><span>reps</span><span>RIR</span><span></span></div>
        ${setRows}
      </div>
      <div class="row wrap">
        <button class="btn-sm" data-add-set>${icons.plus} Serie</button>
        ${e.sets.length > 1 ? `<button class="btn-sm btn-ghost" data-del-set>Quitar serie</button>` : ''}
      </div>
      ${why.length ? `<details style="margin-top:10px"><summary>¿Por qué este peso?</summary>
        <div class="small muted" style="margin-top:6px">${why.map((w) => `<p>${esc(w)}</p>`).join('')}</div></details>` : ''}
      <details style="margin-top:6px"><summary>Notas y cambios</summary>
        <div style="margin-top:8px">
          <div class="flags">${Object.entries(FLAGS).map(([k, v]) => `<button class="chip ${e.flags?.includes(k) ? 'on' : ''}" data-flag="${k}">${esc(v)}</button>`).join('')}</div>
          <label class="field" style="margin-top:8px"><span>Nota</span><input data-note value="${esc(e.note)}" placeholder="p. ej. asiento en 4"></label>
          <div class="row wrap" style="margin-top:8px">
            <button class="btn-sm" data-swap>${icons.swap} Cambiar por otro ejercicio</button>
            ${!item && !s.finished ? `<button class="btn-sm btn-ghost" data-remove-ex>Quitar de hoy</button>` : ''}
          </div>
        </div>
      </details>
    </div>
  </div>`;
}

export function mount(root, rerender, { id }) {
  const s = () => store.sessionById(id);
  if (!s()) return;
  requestWakeLock();

  const refreshCard = (i) => {
    const el = root.querySelector(`[data-entry="${i}"]`);
    const tmp = document.createElement('div');
    tmp.innerHTML = entryCard(s(), s().entries[i], i);
    el.replaceWith(tmp.firstElementChild);
    const count = root.querySelector('[data-done-count]');
    if (count) count.textContent = s().entries.reduce((n, e) => n + workingSets(e).length, 0);
  };

  const entriesEl = root.querySelector('#entries');

  entriesEl.addEventListener('click', async (ev) => {
    const card = ev.target.closest('[data-entry]');
    if (!card) return;
    const i = Number(card.dataset.entry);
    const t = ev.target;

    if (t.closest('[data-toggle]')) {
      const set = expanded.get(id);
      set.has(i) ? set.delete(i) : set.add(i);
      card.classList.toggle('collapsed');
      return;
    }
    if (t.closest('[data-check]')) {
      const j = Number(t.closest('[data-set]').dataset.set);
      const row = t.closest('[data-set]');
      const kg = parseNum(row.querySelector('[data-f=kg]').value);
      const reps = parseNum(row.querySelector('[data-f=reps]').value);
      const rirVal = row.querySelector('[data-f=rir]').value;
      const entry = s().entries[i];
      const wasDone = entry.sets[j].done;
      if (!wasDone && !(reps > 0)) {
        toast('Apunta las repeticiones antes de marcar la serie');
        row.querySelector('[data-f=reps]').focus();
        return;
      }
      store.update(() => {
        Object.assign(entry.sets[j], { kg, reps, rir: rirVal === '' ? null : Number(rirVal), done: !wasDone });
        const next = entry.sets[j + 1];
        if (!wasDone && next && !next.done && kg != null) next.kg = kg;
      });
      if (!wasDone) {
        const ex = store.exercises()[entry.exerciseId];
        const st = store.get().settings;
        if (!s().finished) startRest(ex?.compound ? st.restCompound : st.restIsolation);
        if (isComplete(entry)) {
          expanded.get(id).delete(i);
          const nextIdx = s().entries.findIndex((e, k) => k > i && !isComplete(e));
          if (nextIdx !== -1) { expanded.get(id).add(nextIdx); refreshCard(nextIdx); }
        }
      }
      refreshCard(i);
      return;
    }
    if (t.closest('[data-add-set]')) {
      store.update(() => {
        const e = s().entries[i];
        const lastSet = e.sets[e.sets.length - 1];
        e.sets.push({ kg: lastSet?.kg ?? null, reps: null, rir: null, done: false });
      });
      return refreshCard(i);
    }
    if (t.closest('[data-del-set]')) {
      store.update(() => s().entries[i].sets.pop());
      return refreshCard(i);
    }
    if (t.closest('[data-flag]')) {
      const k = t.closest('[data-flag]').dataset.flag;
      store.update(() => {
        const e = s().entries[i];
        e.flags = e.flags?.includes(k) ? e.flags.filter((x) => x !== k) : [...(e.flags ?? []), k];
      });
      return refreshCard(i);
    }
    if (t.closest('[data-swap]')) return swapExercise(s(), i, rerender);
    if (t.closest('[data-remove-ex]')) {
      store.update(() => s().entries.splice(i, 1));
      return rerender();
    }
  });

  entriesEl.addEventListener('change', (ev) => {
    const card = ev.target.closest('[data-entry]');
    if (!card) return;
    const i = Number(card.dataset.entry);
    const e = s().entries[i];
    if (ev.target.matches('[data-note]')) return store.update(() => (e.note = ev.target.value));
    const row = ev.target.closest('[data-set]');
    if (!row) return;
    const j = Number(row.dataset.set);
    const f = ev.target.dataset.f;
    store.update(() => {
      if (f === 'rir') e.sets[j].rir = ev.target.value === '' ? null : Number(ev.target.value);
      else e.sets[j][f] = parseNum(ev.target.value);
    });
  });

  root.querySelector('[data-session-note]').onchange = (ev) => store.update(() => (s().note = ev.target.value));

  root.querySelector('[data-add-ex]').onclick = async () => {
    const exId = await pickExercise({ title: 'Añadir ejercicio', exclude: s().entries.map((e) => e.exerciseId) });
    if (!exId) return;
    const range = [10, 12];
    store.update(() => s().entries.push(newEntry(exId, range, [3, 3], false, store.blockById(s().blockId))));
    expanded.get(id).add(s().entries.length - 1);
    rerender();
  };

  root.querySelectorAll('[data-finish]').forEach((b) => (b.onclick = () => finish(s())));

  root.querySelector('[data-discard]').onclick = async () => {
    const ok = await confirmDialog(s().finished ? '¿Eliminar esta sesión y sus datos?' : '¿Descartar esta sesión? Se borrarán las series apuntadas hoy.', { ok: 'Borrar', danger: true });
    if (!ok) return;
    store.update((st) => {
      st.sessions = st.sessions.filter((x) => x.id !== id);
      if (st.activeSessionId === id) st.activeSessionId = null;
    });
    stopRest();
    location.hash = '#/';
  };
}

export function unmount() {
  wakeLock?.release?.().catch(() => {});
  wakeLock = null;
}

async function requestWakeLock() {
  try {
    wakeLock = await navigator.wakeLock?.request('screen');
  } catch { /* no disponible */ }
}

function parseNum(v) {
  if (v === '' || v == null) return null;
  const n = Number(String(v).replace(',', '.'));
  return Number.isFinite(n) ? n : null;
}

async function swapExercise(session, i, rerender) {
  const entry = session.entries[i];
  const ex = store.exercises()[entry.exerciseId];
  const block = store.blockById(session.blockId);
  const inPlan = block?.days.find((d) => d.id === session.dayId)?.items.some((it) => it.exerciseId === entry.exerciseId);
  const toId = await pickExercise({
    title: `Sustituir ${ex?.name ?? ''}`,
    preferMuscles: [...(ex?.muscles.p ?? [])],
    exclude: [entry.exerciseId],
  });
  if (!toId) return;
  const to = store.exercises()[toId];

  const res = await modal(
    `<h2>Sustituir ejercicio</h2>
     <p class="muted small">${esc(ex?.name)} → <strong>${esc(to.name)}</strong></p>
     <label class="field"><span>Motivo (te ayudará a decidir en el futuro)</span>
       <textarea name="reason" placeholder="Molestia lumbar, máquina ocupada, estancada 3 semanas…"></textarea></label>
     ${inPlan && !session.finished ? `<label class="row"><input type="checkbox" name="plan" style="width:auto;min-height:0" checked> <span>Cambiarlo también en el plan a partir de esta semana</span></label>` : ''}
     <div class="row" style="justify-content:flex-end"><button class="btn-ghost" data-c>Cancelar</button><button class="btn-primary" data-ok>Sustituir</button></div>`,
    (dlg, close) => {
      dlg.querySelector('[data-c]').onclick = () => close(null);
      dlg.querySelector('[data-ok]').onclick = () => close({
        reason: dlg.querySelector('[name=reason]').value.trim(),
        plan: dlg.querySelector('[name=plan]')?.checked ?? false,
      });
    },
  );
  if (!res) return;

  store.update(() => {
    const fresh = newEntry(toId, entry.range, entry.setsPlan ?? [3, 3], entry.optional, block);
    fresh.note = res.reason ? `Sustituye a ${ex?.name}: ${res.reason}` : `Sustituye a ${ex?.name}`;
    session.entries[i] = fresh;
    if (res.plan && block) {
      for (const d of block.days) for (const it of d.items) if (it.exerciseId === entry.exerciseId && d.id === session.dayId) it.exerciseId = toId;
      block.changes = [...(block.changes ?? []), { week: session.week, date: store.today(), from: entry.exerciseId, to: toId, reason: res.reason }];
    }
  });
  toast(res.plan ? 'Sustituido hoy y en el plan' : 'Sustituido solo hoy');
  rerender();
}

async function finish(session) {
  const empty = session.entries.filter((e) => !e.optional && workingSets(e).length === 0);
  if (empty.length) {
    const ok = await confirmDialog(`${empty.length} ejercicio(s) sin ninguna serie marcada. ¿Terminar igualmente?`, { ok: 'Terminar' });
    if (!ok) return;
  }
  // Récords: mejor 1RM estimado de la historia de cada ejercicio.
  const prs = [];
  for (const e of session.entries) {
    const b = bestSet(e);
    if (!b) continue;
    const prev = historyOf(e.exerciseId).filter((h) => h.session.id !== session.id);
    const prevBest = Math.max(0, ...prev.map((h) => bestSet(h.entry)?.e1rm ?? 0));
    if (prev.length && b.e1rm > prevBest * 1.005) prs.push(`${store.exercises()[e.exerciseId]?.name}: ${fmt(b.kg)} kg × ${b.reps}`);
  }
  store.update((st) => {
    session.finished = true;
    session.finishedAt = new Date().toISOString();
    session.entries = session.entries.filter((e) => !(e.optional && workingSets(e).length === 0));
    for (const e of session.entries) e.sets = e.sets.filter((x) => x.done);
    if (st.activeSessionId === session.id) st.activeSessionId = null;
  });
  stopRest();
  const mins = Math.round((Date.parse(session.finishedAt) - Date.parse(session.startedAt)) / 60000);
  const sets = session.entries.reduce((n, e) => n + e.sets.length, 0);
  await modal(
    `<h2>¡Sesión guardada! 💪</h2>
     <div class="stats">
       <div class="stat"><span class="v">${sets}</span><span class="l">series</span></div>
       <div class="stat"><span class="v">${mins}</span><span class="l">minutos</span></div>
     </div>
     ${prs.length ? `<div class="note good"><strong>¡Nuevo récord!</strong><br>${prs.map(esc).join('<br>')}</div>` : ''}
     <button class="btn-primary btn-block" data-ok>Volver al inicio</button>`,
    (dlg, close) => (dlg.querySelector('[data-ok]').onclick = () => close()),
  );
  location.hash = '#/';
}
