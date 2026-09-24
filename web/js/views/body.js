import * as store from '../store.js';
import { esc, fmtDate, confirmDialog } from '../ui.js';
import { weightTrend, fmt, round1, DAY_MS } from '../progression.js';
import { lineChart, hydrateCharts } from '../charts.js';

const isoOf = (ms) => new Date(ms).toISOString().slice(0, 10);

// Lunes de la semana de `iso`.
function mondayOf(iso) {
  const d = new Date(`${iso}T00:00:00Z`);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
}

export function render() {
  const st = store.get();
  const t = store.today();
  const monday = mondayOf(t);
  const days = Array.from({ length: 7 }, (_, i) => isoOf(monday + i * DAY_MS));
  const byDate = Object.fromEntries(st.steps.map((s) => [s.date, s]));

  const cardioDays = days.filter((d) => byDate[d]?.cardioMin >= 10).length;
  const cardioMin = days.reduce((a, d) => a + (byDate[d]?.cardioMin || 0), 0);
  const stepDays = days.filter((d) => byDate[d]?.steps > 0);
  const avgSteps = stepDays.length ? Math.round(stepDays.reduce((a, d) => a + byDate[d].steps, 0) / stepDays.length) : null;
  const goal = st.settings.cardioSessionsGoal;

  const rows = days.map((d) => {
    const s = byDate[d];
    const future = d > t;
    return `<div class="act-row ${d === t ? 'today' : ''}">
      <span class="small">${esc(fmtDate(d, { weekday: 'short', day: 'numeric' }))}</span>
      <input type="number" inputmode="numeric" step="500" data-date="${d}" data-f="steps" value="${s?.steps ?? ''}" placeholder="pasos" ${future ? 'disabled' : ''} aria-label="Pasos ${d}">
      <input type="number" inputmode="numeric" step="5" data-date="${d}" data-f="cardioMin" value="${s?.cardioMin ?? ''}" placeholder="min" ${future ? 'disabled' : ''} aria-label="Minutos de cardio ${d}">
      <span class="dot ${s?.cardioMin >= 10 ? 'on' : ''}" aria-hidden="true"></span>
    </div>`;
  }).join('');

  const { points } = weightTrend(st.bodyweight);
  const today = st.bodyweight.find((b) => b.date === t);
  const waistOf = (date) => st.bodyweight.find((b) => b.date === date)?.waist;

  return `<h1>Actividad</h1>
    <div class="card stack">
      <h2 style="margin:0">Esta semana</h2>
      <div class="stats">
        <div class="stat"><span class="v num">${cardioDays}/${goal}</span><span class="l">días de cardio · ${cardioMin} min</span></div>
        <div class="stat"><span class="v num">${avgSteps !== null ? avgSteps.toLocaleString('es-ES') : '–'}</span><span class="l">pasos al día de media</span></div>
      </div>
      <div>
        <div class="act-row head small faint"><span></span><span>Pasos</span><span>Cardio (min)</span><span></span></div>
        ${rows}
      </div>
      <p class="small faint">Aproximado está bien. Puedes rellenar días pasados cuando quieras.</p>
    </div>

    <details class="card">
      <summary><strong>Peso y cintura (opcional)</strong></summary>
      <div class="stack" style="margin-top:10px">
        <p class="small muted">Solo si te apetece. No hace falta.</p>
        <div class="row">
          <label class="field grow"><span>Peso (kg)</span><input id="bw" type="number" inputmode="decimal" step="0.1" value="${today?.kg ?? ''}"></label>
          <label class="field grow"><span>Cintura (cm)</span><input id="waist" type="number" inputmode="decimal" step="0.5" value="${today?.waist ?? ''}"></label>
        </div>
        ${points.length > 1 ? lineChart([{ name: 'Peso', points: points.map((p) => ({ x: Date.parse(p.date), y: round1(p.kg), label: `${fmtDate(p.date, { day: 'numeric', month: 'short' })} · ${fmt(p.kg)} kg${waistOf(p.date) ? ` · cintura ${fmt(waistOf(p.date))} cm` : ''}` })) }], { unit: 'kg', ariaLabel: 'Evolución del peso' }) : ''}
        ${st.bodyweight.length ? `<table class="data"><tbody>
          ${[...st.bodyweight].sort((a, b) => b.date.localeCompare(a.date)).slice(0, 20).map((b) => `<tr><td>${esc(fmtDate(b.date))}</td><td>${fmt(b.kg)} kg</td><td>${b.waist ? fmt(b.waist) + ' cm' : ''}</td>
          <td style="text-align:right"><button class="btn-sm btn-ghost" data-del-bw="${b.date}" aria-label="Borrar">✕</button></td></tr>`).join('')}
        </tbody></table>` : ''}
      </div>
    </details>`;
}

export function mount(root, rerender) {
  hydrateCharts(root);
  const t = store.today();

  root.querySelectorAll('[data-date]').forEach((el) => (el.onchange = () => {
    const date = el.dataset.date;
    const v = el.value.trim() === '' ? null : Number(el.value.replace(',', '.'));
    store.update((st) => {
      let s = st.steps.find((x) => x.date === date);
      if (!s) { s = { date, steps: null, cardioMin: null }; st.steps.push(s); }
      s[el.dataset.f] = Number.isFinite(v) ? v : null;
      if (s.steps == null && s.cardioMin == null) st.steps = st.steps.filter((x) => x !== s);
    });
    rerender();
  }));

  const save = () => {
    const kg = Number(root.querySelector('#bw').value.replace(',', '.'));
    const waist = Number(root.querySelector('#waist').value.replace(',', '.'));
    store.update((st) => {
      st.bodyweight = st.bodyweight.filter((b) => b.date !== t);
      if (kg > 0) st.bodyweight.push({ date: t, kg, ...(waist > 0 ? { waist } : {}) });
    });
    rerender();
  };
  root.querySelector('#bw').onchange = save;
  root.querySelector('#waist').onchange = save;
  root.querySelectorAll('[data-del-bw]').forEach((b) => (b.onclick = async () => {
    if (!(await confirmDialog('¿Borrar este registro?', { ok: 'Borrar', danger: true }))) return;
    store.update((st) => (st.bodyweight = st.bodyweight.filter((x) => x.date !== b.dataset.delBw)));
    rerender();
  }));
}
