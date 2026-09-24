import * as store from '../store.js';
import { esc, fmtDate, muscleName, icons, toast } from '../ui.js';
import { historyOf, lastText, stallFor } from '../coach.js';
import { bestSet, fmt } from '../progression.js';
import { lineChart, hydrateCharts } from '../charts.js';

export function renderList() {
  const block = store.activeBlock();
  const ex = store.exercises();
  const inBlock = [...new Set(block.days.flatMap((d) => d.items.map((i) => i.exerciseId)))];
  const withHistory = [...new Set(store.finishedSessions().flatMap((s) => s.entries.map((e) => e.exerciseId)))];
  const past = withHistory.filter((id) => !inBlock.includes(id));

  const row = (id) => {
    const h = historyOf(id);
    const change = trend(h);
    return `<li><a class="list-link" href="#/ejercicio/${id}">
      <span class="grow"><span>${esc(ex[id]?.name ?? id)}</span><br>
      <span class="small muted">${h.length ? esc(lastText(h[0])) : 'sin registros'}</span></span>
      ${stallFor(id) ? '<span class="chip warn">estancado</span>' : change !== null ? `<span class="chip ${change > 0 ? 'good' : change < 0 ? 'bad' : ''} num">${change > 0 ? '▲' : change < 0 ? '▼' : '='} ${fmt(Math.abs(change))} %</span>` : ''}
    </a></li>`;
  };

  return `<h1>Progreso</h1>
    <p class="muted small">Cuánto ha subido tu fuerza en las últimas 8 semanas.</p>
    <div class="card"><h2>${esc(block.name)}</h2><ul class="list">${inBlock.map(row).join('')}</ul></div>
    ${past.length ? `<div class="card"><h2>Ejercicios anteriores</h2><ul class="list">${past.map(row).join('')}</ul></div>` : ''}`;
}

// % de cambio del 1RM estimado frente a hace ~8 semanas (o el primer registro).
function trend(h) {
  if (h.length < 2) return null;
  const now = bestSet(h[0].entry)?.e1rm;
  const cutoff = Date.parse(h[0].date) - 56 * 86400000;
  const ref = h.find((x) => Date.parse(x.date) <= cutoff) ?? h[h.length - 1];
  const then = bestSet(ref.entry)?.e1rm;
  if (!now || !then) return null;
  return Math.round(((now - then) / then) * 1000) / 10;
}

export function renderDetail({ id }) {
  const ex = store.exercises()[id];
  if (!ex) return '<p>Ejercicio no encontrado.</p>';
  const h = historyOf(id);
  const points = [...h].reverse().map((x) => {
    const b = bestSet(x.entry);
    return {
      x: Date.parse(x.date),
      y: Math.round(b.e1rm * 10) / 10,
      label: `${fmtDate(x.date, { day: 'numeric', month: 'short' })} · ${fmt(b.kg)} kg × ${b.reps}`,
    };
  });
  const loaded = points.some((p) => p.y > 0);
  const changes = store.get().blocks.flatMap((b) => (b.changes ?? []).filter((c) => c.from === id || c.to === id).map((c) => ({ ...c, block: b.name })));
  const flags = h.flatMap((x) => (x.entry.flags ?? []).map((f) => ({ f, date: x.date })));

  return `
    <a href="#/progreso" class="btn btn-ghost icon-btn" aria-label="Volver">${icons.back}</a>
    <h1>${esc(ex.name)}</h1>
    <div class="chips" style="margin-bottom:12px">${ex.muscles.p.map((m) => `<span class="chip">${esc(muscleName(m))}</span>`).join('')}${ex.muscles.s.map((m) => `<span class="chip" style="opacity:.7">${esc(muscleName(m))} ½</span>`).join('')}</div>
    ${loaded ? `<div class="card">
      <h2>Tu fuerza</h2>
      <p class="small muted">Si la línea sube, estás progresando. Toca la gráfica para ver cada día.</p>
      ${lineChart([{ name: '1RM estimado', points }], { unit: 'kg', ariaLabel: `Evolución de la fuerza estimada en ${ex.name}` })}
    </div>` : ''}
    ${stallFor(id) ? `<div class="note warn" style="margin-top:12px">Sin progreso en peso ni repeticiones en las últimas 3 sesiones.</div>` : ''}
    <details class="card">
      <summary><strong>Cuánto subir de peso</strong></summary><div style="margin-top:10px">
      <label class="field"><span>Incremento de carga (kg)${ex.equip === 'mancuerna' ? ' por mancuerna' : ''}</span>
      <input id="inc" type="number" step="0.5" min="0" inputmode="decimal" value="${ex.inc}"></label>
      <p class="small faint">Pon el salto más pequeño que permita tu gimnasio.</p>
    </div></details>
    ${changes.length ? `<div class="card"><h2>Cambios</h2><ul class="list">${changes.map((c) => `<li class="small">${esc(c.block)}, sem. ${c.week}: ${c.to === id ? 'entra' : 'sale'}${c.reason ? ` — <span class="muted">${esc(c.reason)}</span>` : ''}</li>`).join('')}</ul></div>` : ''}
    ${flags.length ? `<div class="note warn" style="margin-top:12px">Sensaciones anotadas: ${flags.map((x) => `${esc(fmtDate(x.date, { day: 'numeric', month: 'short' }))} (${esc(x.f.replace('_', ' '))})`).join(', ')}</div>` : ''}
    <div class="card">
      <h2>Historial</h2>
      ${h.length ? `<table class="data"><thead><tr><th>Fecha</th><th>Lo que hiciste</th><th>Nota</th></tr></thead><tbody>
        ${h.map((x) => `<tr><td>${esc(fmtDate(x.date, { day: 'numeric', month: 'short', year: '2-digit' }))}${x.session.approxDate ? '*' : ''}<br><span class="faint">sem. ${x.week}</span></td>
        <td>${esc(lastText(x))}</td>
        <td class="small muted">${esc(x.entry.note ?? '')}</td></tr>`).join('')}
      </tbody></table>
      <p class="small faint" style="margin-top:8px">* Del Excel (fecha aproximada).</p>` : '<p class="muted">Sin registros todavía.</p>'}
    </div>`;
}

export function mountDetail(root, rerender, { id }) {
  hydrateCharts(root);
  const inc = root.querySelector('#inc');
  if (inc) inc.onchange = () => {
    const v = Number(inc.value.replace(',', '.'));
    if (!(v >= 0)) return;
    store.update((st) => (st.exerciseOverrides[id] = { ...(st.exerciseOverrides[id] ?? {}), inc: v }));
    toast('Incremento guardado');
  };
}
