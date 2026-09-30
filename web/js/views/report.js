// Pantalla de resumen de un bloque: avances, gráficas y qué significan.
import * as store from '../store.js';
import { esc, fmtDate, muscleName, icons } from '../ui.js';
import { fmt } from '../progression.js';
import { blockReport, reportInsights } from '../report.js';
import { lineChart, hydrateCharts } from '../charts.js';

const signed = (x) => `${x > 0 ? '+' : x < 0 ? '−' : ''}${fmt(Math.abs(x))} %`;
const setText = (b) => `${fmt(b.kg)} kg × ${b.reps}`;

// Barras horizontales desde 0: longitud = |%| respecto al mayor (o a `max`, para compartir escala); las negativas en rojo.
function bars(rows, max = Math.max(1, ...rows.map((r) => Math.abs(r.pct ?? 0)))) {
  return `<ul class="rbars">${rows.map((r) => `<li>
    <div class="row spread"><span class="grow">${r.label}</span><strong class="num">${r.pct === null ? '<span class="faint small">sin peso</span>' : signed(r.pct)}</strong></div>
    ${r.pct === null ? '' : `<div class="rbar-track"><div class="rbar ${r.pct < 0 ? 'neg' : ''}" style="width:${Math.max(2, (Math.abs(r.pct) / max) * 100)}%"></div></div>`}
    ${r.sub ? `<div class="small muted">${r.sub}</div>` : ''}
  </li>`).join('')}</ul>`;
}

const exerciseRow = (e) => ({
  pct: e.pct,
  label: `<a href="#/ejercicio/${e.id}" class="rlink">${esc(e.name)}</a>${e.stalled ? ' <span class="chip warn">estancado</span>' : ''}`,
  sub: e.pct === null ? `${e.sessions} ${e.sessions === 1 ? 'sesión' : 'sesiones'}` : `${setText(e.first)} → ${setText(e.last)}`,
});

export function render({ id }) {
  const st = store.get();
  const block = store.blockById(id);
  if (!block) return '<p>Bloque no encontrado.</p>';
  const r = blockReport({ block, sessions: st.sessions, exercises: store.exercises(), steps: st.steps, bodyweight: st.bodyweight });
  const back = `<a href="#/progreso" class="btn btn-ghost icon-btn" aria-label="Volver">${icons.back}</a>`;
  if (!r.sessions) return `${back}<h1>${esc(block.name)}</h1><p class="muted">Todavía no hay entrenos en este bloque.</p>`;

  const finished = block.archived || !store.nextSlot(block);
  const insights = reportInsights(r, muscleName);
  const weeks = `semanas ${block.weeks[0]}–${block.weeks[block.weeks.length - 1]}`;

  let html = `${back}
    <div class="eyebrow">${finished ? 'Bloque terminado' : 'Bloque en curso'} · ${esc(weeks)}</div>
    <h1>${esc(block.name)}</h1>
    <p class="muted small">${esc(fmtDate(r.from, { day: 'numeric', month: 'long' }))} – ${esc(fmtDate(r.to, { day: 'numeric', month: 'long' }))}${r.imported ? ' (fechas aproximadas)' : ''}</p>`;

  // Cifra principal
  html += `<div class="card accent stack">
    ${r.avgPct !== null ? `<div>
      <div class="hero-num num ${r.avgPct < 0 ? 'neg' : ''}">${signed(r.avgPct)}</div>
      <div class="muted">de fuerza de media en ${r.perExercise.filter((e) => e.pct !== null).length} ejercicios</div>
    </div>` : ''}
    <div class="stats">
      <div class="stat"><span class="v num">${r.sessions}/${r.planned}</span><span class="l">entrenos</span></div>
      ${r.imported ? `<div class="stat"><span class="v num">${r.weeksTrained}</span><span class="l">semanas entrenadas</span></div>` : `
      <div class="stat"><span class="v num">${r.totalSets}</span><span class="l">series</span></div>
      <div class="stat"><span class="v num">${Math.round(r.tonnage / 1000).toLocaleString('es-ES')} t</span><span class="l">levantadas en total</span></div>`}
    </div>
  </div>`;

  // Evolución semanal
  if (r.weekly.length > 1) {
    html += `<div class="card">
      <h2>Tu fuerza semana a semana</h2>
      <p class="small muted">0 % es cómo empezaste cada ejercicio. Si la línea sube, estás progresando. Toca la gráfica para ver cada semana.</p>
      ${lineChart([{ name: 'Fuerza', points: r.weekly.map((w) => ({ x: w.week, y: Math.round(w.pct * 10) / 10, label: `Semana ${w.week} · ${signed(w.pct)}` })) }], { unit: '%', ariaLabel: 'Evolución de la fuerza media por semana', xFormat: (w) => (r.weekly.length > 5 ? `S${w}` : `Sem ${w}`) })}
    </div>`;
  }

  // Qué significa
  if (insights.length) {
    html += `<div class="card stack"><h2 style="margin:0">Qué significa</h2>
      ${insights.map((i) => `<div class="note ${i.tone === 'info' ? '' : i.tone}"><strong>${esc(i.title)}</strong><br>${esc(i.text)}</div>`).join('')}
    </div>`;
  }

  // Ejercicio a ejercicio (los sustituidos, aparte)
  const replaced = r.perExercise.filter((e) => e.replaced);
  const scale = Math.max(1, ...r.perExercise.map((e) => Math.abs(e.pct ?? 0)));
  html += `<div class="card"><h2>Ejercicio a ejercicio</h2>
    <p class="small muted">Primera → última sesión del bloque. Toca uno para ver su gráfica.</p>
    ${bars(r.perExercise.filter((e) => !e.replaced).map(exerciseRow), scale)}
    ${replaced.length ? `<details style="margin-top:14px"><summary>Ejercicios que sustituiste durante el bloque (${replaced.length})</summary>
      <div style="margin-top:10px">${bars(replaced.map(exerciseRow), scale)}</div></details>` : ''}
  </div>`;

  // Por músculo
  if (r.muscles.length > 1) {
    html += `<div class="card"><h2>Por músculo</h2>
      <p class="small muted">Media de los ejercicios en los que ese músculo es el principal.</p>
      ${bars(r.muscles.map((m) => ({ pct: m.pct, label: esc(muscleName(m.muscle)), sub: '' })))}
    </div>`;
  }

  // Actividad y cuerpo
  if (r.cardioDays || r.avgSteps || r.bodyweight) {
    html += `<div class="card"><h2>Fuera del gimnasio</h2><div class="stats">
      ${r.cardioDays ? `<div class="stat"><span class="v num">${r.cardioDays}</span><span class="l">días de cardio · ${r.cardioMin} min</span></div>` : ''}
      ${r.avgSteps ? `<div class="stat"><span class="v num">${r.avgSteps.toLocaleString('es-ES')}</span><span class="l">pasos al día de media</span></div>` : ''}
      ${r.bodyweight ? `<div class="stat"><span class="v num">${fmt(r.bodyweight.from)} → ${fmt(r.bodyweight.to)}</span><span class="l">kg de peso corporal</span></div>` : ''}
    </div></div>`;
  }

  html += `<details class="card"><summary><strong>¿Qué mide este porcentaje?</strong></summary><div class="stack small muted" style="margin-top:10px">
    <p>Es tu <strong>fuerza estimada</strong>: el peso que podrías levantar una sola vez, calculado a partir de tus series (kilos, repeticiones y RIR). Así se pueden comparar semanas aunque cambies de 6–8 a 10–12 repeticiones.</p>
    <p>La fuerza sube antes que el tamaño del músculo: al principio gran parte de la mejora es que tu cuerpo aprende el movimiento. Que la fuerza siga subiendo bloque tras bloque es la mejor señal práctica de que el músculo está creciendo.</p>
    <p>Un bloque con poca subida no es un fracaso: tras un descanso o un cambio de ejercicio es normal. Lo importante es la tendencia de varios bloques.</p>
    ${r.imported ? '<p>Este bloque se importó del Excel, que guardaba una sola serie por ejercicio y semana, así que no se muestran series ni kilos totales.</p>' : ''}
  </div></details>`;

  if (finished && store.activeBlock().id === block.id) {
    html += `<a class="btn btn-primary btn-block" style="margin-top:12px" href="#/plan">Crear el siguiente bloque</a>`;
  }
  return html;
}

export function mount(root) {
  hydrateCharts(root);
}
