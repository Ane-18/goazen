// Gráfica de líneas en SVG con tooltip al tocar / pasar el dedo.
// series: [{ name, points: [{ x: ms, y, label }], style: 'line' | 'dots' }]
import { fmt } from './progression.js';

const W = 340;
const H = 180;
const PAD = { l: 34, r: 12, t: 12, b: 24 };

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

function niceTicks(min, max, count = 4) {
  if (min === max) { min -= 1; max += 1; }
  const span = max - min;
  const step0 = span / count;
  const mag = 10 ** Math.floor(Math.log10(step0));
  const step = [1, 2, 2.5, 5, 10].map((m) => m * mag).find((s) => s >= step0) ?? 10 * mag;
  const lo = Math.floor(min / step) * step;
  const hi = Math.ceil(max / step) * step;
  const ticks = [];
  for (let v = lo; v <= hi + step / 2; v += step) ticks.push(Math.round(v * 100) / 100);
  return ticks;
}

const shortDate = (ms) => new Date(ms).toLocaleDateString('es-ES', { day: 'numeric', month: 'short' });

export function lineChart(series, { unit = 'kg', ariaLabel = '' } = {}) {
  const all = series.flatMap((s) => s.points);
  if (all.length === 0) return '<p class="muted small">Sin datos todavía.</p>';
  const xs = all.map((p) => p.x);
  const ys = all.map((p) => p.y);
  let x0 = Math.min(...xs);
  let x1 = Math.max(...xs);
  if (x0 === x1) { x0 -= 86400000 * 3; x1 += 86400000 * 3; }
  const ticks = niceTicks(Math.min(...ys), Math.max(...ys));
  const y0 = ticks[0];
  const y1 = ticks[ticks.length - 1];
  const sx = (x) => PAD.l + ((x - x0) / (x1 - x0)) * (W - PAD.l - PAD.r);
  const sy = (y) => PAD.t + (1 - (y - y0) / (y1 - y0)) * (H - PAD.t - PAD.b);

  let svg = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(ariaLabel)}">`;
  for (const t of ticks) {
    svg += `<line x1="${PAD.l}" x2="${W - PAD.r}" y1="${sy(t)}" y2="${sy(t)}" stroke="var(--chart-grid)" stroke-width="1"/>`;
    svg += `<text x="${PAD.l - 6}" y="${sy(t) + 4}" text-anchor="end" font-size="10" fill="var(--muted)">${fmt(t)}</text>`;
  }
  const xTicks = [x0, (x0 + x1) / 2, x1];
  xTicks.forEach((t, i) => {
    const anchor = i === 0 ? 'start' : i === 2 ? 'end' : 'middle';
    svg += `<text x="${sx(t)}" y="${H - 6}" text-anchor="${anchor}" font-size="10" fill="var(--muted)">${shortDate(t)}</text>`;
  });

  for (const s of series) {
    const pts = [...s.points].sort((a, b) => a.x - b.x);
    if (s.style === 'dots') {
      for (const p of pts) svg += `<circle cx="${sx(p.x)}" cy="${sy(p.y)}" r="3" fill="var(--chart-muted)"/>`;
    } else {
      const d = pts.map((p, i) => `${i ? 'L' : 'M'}${sx(p.x).toFixed(1)},${sy(p.y).toFixed(1)}`).join('');
      svg += `<path d="${d}" fill="none" stroke="var(--primary)" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;
      const last = pts[pts.length - 1];
      svg += `<circle cx="${sx(last.x)}" cy="${sy(last.y)}" r="4.5" fill="var(--primary)" stroke="var(--surface)" stroke-width="2"/>`;
    }
  }
  svg += `<line class="xhair" x1="0" x2="0" y1="${PAD.t}" y2="${H - PAD.b}" stroke="var(--muted)" stroke-width="1" visibility="hidden"/>`;
  svg += `<circle class="hover-dot" r="5" fill="var(--primary)" stroke="var(--surface)" stroke-width="2" visibility="hidden"/>`;
  svg += '</svg>';

  // Datos para el tooltip: la serie principal (línea) manda.
  const main = series.find((s) => s.style !== 'dots') ?? series[0];
  const hover = [...main.points].sort((a, b) => a.x - b.x).map((p) => ({
    px: sx(p.x), py: sy(p.y), label: p.label ?? `${shortDate(p.x)} · ${fmt(p.y)} ${unit}`,
  }));
  return `<div class="chart" data-hover='${esc(JSON.stringify(hover))}'>${svg}<div class="tip hidden"></div></div>`;
}

export function hydrateCharts(root) {
  for (const el of root.querySelectorAll('.chart[data-hover]')) {
    const pts = JSON.parse(el.dataset.hover);
    const svg = el.querySelector('svg');
    const tip = el.querySelector('.tip');
    const xh = svg.querySelector('.xhair');
    const dot = svg.querySelector('.hover-dot');
    const show = (ev) => {
      const r = svg.getBoundingClientRect();
      const x = ((ev.clientX - r.left) / r.width) * W;
      let best = pts[0];
      for (const p of pts) if (Math.abs(p.px - x) < Math.abs(best.px - x)) best = p;
      xh.setAttribute('x1', best.px); xh.setAttribute('x2', best.px); xh.setAttribute('visibility', 'visible');
      dot.setAttribute('cx', best.px); dot.setAttribute('cy', best.py); dot.setAttribute('visibility', 'visible');
      tip.textContent = best.label;
      tip.classList.remove('hidden');
      const left = (best.px / W) * r.width;
      tip.style.left = `${Math.min(Math.max(left, 70), r.width - 70)}px`;
      tip.style.top = `${(best.py / H) * r.height}px`;
    };
    const hide = () => {
      tip.classList.add('hidden');
      xh.setAttribute('visibility', 'hidden');
      dot.setAttribute('visibility', 'hidden');
    };
    el.addEventListener('pointerdown', show);
    el.addEventListener('pointermove', show);
    el.addEventListener('pointerleave', hide);
  }
}
