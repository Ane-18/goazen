// Calendario mensual: días de gimnasio, días de cardio y los días que tocan del bloque activo.
import * as store from '../store.js';
import { esc, icons } from '../ui.js';
import { DAY_MS } from '../progression.js';

const isoOf = (ms) => new Date(ms).toISOString().slice(0, 10);
const utc = (iso) => Date.parse(`${iso}T00:00:00Z`);
const weekdayOf = (iso) => ((new Date(utc(iso)).getUTCDay() + 6) % 7) + 1; // 1 = lunes

let month = null; // 'YYYY-MM' que se está viendo

// Días en que toca gimnasio según el bloque activo (desde hoy o el inicio hasta el final del bloque).
function plannedDays(block, t) {
  const weekdays = new Set(block.days.map((d) => d.weekday).filter(Boolean));
  if (!weekdays.size || !block.startDate || !store.nextSlot(block)) return new Set();
  const from = Math.max(utc(t), utc(block.trialStart ?? block.startDate));
  const monday = utc(block.startDate) - (weekdayOf(block.startDate) - 1) * DAY_MS;
  const until = monday + block.weeks.length * 7 * DAY_MS;
  const out = new Set();
  for (let ms = from; ms < until; ms += DAY_MS) if (weekdays.has(weekdayOf(isoOf(ms)))) out.add(isoOf(ms));
  return out;
}

export function calendarCard() {
  const st = store.get();
  const t = store.today();
  month ??= t.slice(0, 7);
  const [y, m] = month.split('-').map(Number);
  const first = Date.UTC(y, m - 1, 1);
  const nDays = new Date(Date.UTC(y, m, 0)).getUTCDate();
  const lead = weekdayOf(isoOf(first)) - 1;

  const gym = {};
  for (const s of st.sessions) if (s.finished) (gym[s.date] ??= []).push(s);
  const cardio = new Set(st.steps.filter((s) => s.cardioMin >= 10).map((s) => s.date));
  const planned = plannedDays(store.activeBlock(), t);

  let trained = 0, cardioN = 0, approx = false;
  const cells = [];
  for (let i = 0; i < lead; i++) cells.push('<span></span>');
  for (let d = 1; d <= nDays; d++) {
    const iso = isoOf(first + (d - 1) * DAY_MS);
    const g = gym[iso];
    if (g) trained++;
    if (cardio.has(iso)) cardioN++;
    if (g?.every((s) => s.approxDate)) approx = true;
    const cls = [
      g ? 'gym' : '',
      g?.every((s) => s.approxDate) ? 'approx' : '',
      !g && planned.has(iso) ? 'planned' : '',
      iso === t ? 'today' : '',
    ].join(' ');
    const label = [g ? 'entreno' : '', cardio.has(iso) ? 'cardio' : '', !g && planned.has(iso) ? 'toca gimnasio' : ''].filter(Boolean).join(', ');
    const inner = `${d}${cardio.has(iso) ? '<i class="cdot"></i>' : ''}`;
    cells.push(g
      ? `<a class="cal-day ${cls}" href="#/sesion/${g[0].id}" aria-label="${d}: ${label}">${inner}</a>`
      : `<span class="cal-day ${cls}"${label ? ` aria-label="${d}: ${label}"` : ''}>${inner}</span>`);
  }

  const title = new Date(first).toLocaleDateString('es-ES', { month: 'long', year: 'numeric', timeZone: 'UTC' })
    .replace(/^\p{L}/u, (c) => c.toUpperCase());
  return `<div class="card stack">
    <div class="row spread">
      <button class="btn-sm btn-ghost icon-btn" data-cal="-1" aria-label="Mes anterior">${icons.back}</button>
      <h2 style="margin:0">${esc(title)}</h2>
      <button class="btn-sm btn-ghost icon-btn" data-cal="1" aria-label="Mes siguiente" style="transform:scaleX(-1)">${icons.back}</button>
    </div>
    <div class="stats">
      <div class="stat"><span class="v num">${trained}</span><span class="l">${trained === 1 ? 'entreno' : 'entrenos'}</span></div>
      <div class="stat"><span class="v num">${cardioN}</span><span class="l">días de cardio</span></div>
    </div>
    <div class="cal">
      ${['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((w) => `<span class="cal-wd">${w}</span>`).join('')}
      ${cells.join('')}
    </div>
    <div class="cal-legend small muted">
      <span><i class="sw gym"></i>Gimnasio</span>
      <span><i class="sw cdot"></i>Cardio</span>
      <span><i class="sw planned"></i>Toca</span>
    </div>
    ${approx ? '<p class="small faint" style="margin:0">Los entrenos de las semanas 1–8 tienen fecha aproximada (el Excel solo guardaba la semana).</p>' : ''}
  </div>`;
}

export function mountCalendar(root, rerender) {
  root.querySelectorAll('[data-cal]').forEach((b) => (b.onclick = () => {
    const [y, m] = month.split('-').map(Number);
    const d = new Date(Date.UTC(y, m - 1 + Number(b.dataset.cal), 1));
    month = d.toISOString().slice(0, 7);
    rerender();
  }));
}
