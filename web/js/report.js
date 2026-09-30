// Resumen de un bloque terminado: cuánto has progresado y qué significa.
// Funciones puras (sin DOM ni almacenamiento) para poder probarlas con `node --test`.
//
// Compara la fuerza estimada (1RM) de la primera y la última sesión de cada ejercicio
// dentro del bloque. El 1RM estimado tiene en cuenta kg, reps y RIR, así que se puede
// comparar aunque cambie el rango de repeticiones (p. ej. 6–8 → 10–12).
import { exerciseHistory, bestSet, workingSets, isStalled, doneVolume, fmt } from './progression.js';

const mean = (xs) => (xs.length ? xs.reduce((a, x) => a + x, 0) / xs.length : null);
const pct = (now, then) => ((now - then) / then) * 100;

/**
 * @param {object} p
 * @param {object} p.block
 * @param {Array} p.sessions  todas las sesiones (se filtran las de este bloque)
 * @param {object} p.exercises  catálogo { id: ejercicio }
 * @param {Array} [p.steps]  [{ date, steps, cardioMin }]
 * @param {Array} [p.bodyweight]  [{ date, kg, waist }]
 */
export function blockReport({ block, sessions, exercises, steps = [], bodyweight = [] }) {
  const done = sessions.filter((s) => s.finished && s.blockId === block.id).sort((a, b) => a.date.localeCompare(b.date));
  const planned = block.days.length * block.weeks.length;
  const from = done[0]?.date ?? block.startDate;
  const to = done[done.length - 1]?.date ?? block.startDate;

  let totalSets = 0;
  let tonnage = 0;
  for (const s of done) for (const e of s.entries) for (const x of workingSets(e)) { totalSets++; tonnage += (x.kg || 0) * x.reps; }

  // Por ejercicio
  const ids = [...new Set(done.flatMap((s) => s.entries.map((e) => e.exerciseId)))];
  const lastWeek = Math.max(...done.map((s) => s.week));
  const perExercise = [];
  for (const id of ids) {
    const h = exerciseHistory(done, id); // de la más reciente a la más antigua
    const pts = [...h].reverse().map((x) => ({ date: x.date, best: bestSet(x.entry) })).filter((p) => p.best?.e1rm > 0);
    const ex = exercises[id];
    // Sustituido = no se hizo en las 2 últimas semanas del bloque.
    const replaced = h.length > 0 && h[0].week < lastWeek - 1;
    const base = { id, name: ex?.name ?? id, muscle: ex?.muscles.p[0], sessions: h.length, replaced, flags: h.flatMap((x) => x.entry.flags ?? []) };
    if (pts.length < 2) { perExercise.push({ ...base, pct: null }); continue; }
    const first = pts[0].best;
    const last = pts[pts.length - 1].best;
    perExercise.push({
      ...base,
      first,
      last,
      pct: pct(last.e1rm, first.e1rm),
      points: pts.map((p) => ({ date: p.date, e1rm: p.best.e1rm })),
      stalled: !replaced && isStalled(h),
    });
  }
  const measured = perExercise.filter((e) => e.pct !== null).sort((a, b) => b.pct - a.pct);
  const avgPct = measured.length ? mean(measured.map((e) => e.pct)) : null;

  // Fuerza semana a semana: media de (1RM de esa semana / 1RM de su primera sesión).
  const base = Object.fromEntries(measured.map((e) => [e.id, e.points[0].e1rm]));
  const weekly = [];
  for (const w of block.weeks) {
    const ws = done.filter((s) => s.week === w);
    const ratios = [];
    for (const s of ws) for (const e of s.entries) {
      const b = bestSet(e);
      if (base[e.exerciseId] && b?.e1rm > 0) ratios.push(b.e1rm / base[e.exerciseId]);
    }
    if (ratios.length) weekly.push({ week: w, date: ws[0].date, pct: (mean(ratios) - 1) * 100 });
  }

  // Por músculo principal
  const byMuscle = {};
  for (const e of measured) if (e.muscle) (byMuscle[e.muscle] ??= []).push(e.pct);
  const muscles = Object.entries(byMuscle)
    .map(([muscle, xs]) => ({ muscle, pct: mean(xs), n: xs.length }))
    .sort((a, b) => b.pct - a.pct);

  // Series semanales hechas por músculo (media de las semanas con algún entreno)
  const weeksTrained = new Set(done.map((s) => s.week)).size || 1;
  const weeklySets = Object.fromEntries(Object.entries(doneVolume(done, exercises)).map(([m, v]) => [m, v / weeksTrained]));

  // Actividad y peso durante el bloque
  const inRange = (d) => d >= from && d <= to;
  const st = steps.filter((s) => inRange(s.date));
  const stepDays = st.filter((s) => s.steps > 0);
  const bw = bodyweight.filter((b) => inRange(b.date) && b.kg > 0).sort((a, b) => a.date.localeCompare(b.date));
  const waists = bw.filter((b) => b.waist > 0);

  return {
    // El historial importado del Excel guarda una sola serie por ejercicio y semana:
    // las series y los kilos totales no son reales.
    imported: done.some((s) => s.imported),
    from,
    to,
    sessions: done.length,
    planned,
    adherence: planned ? Math.min(1, done.length / planned) : null,
    weeksTrained,
    totalSets,
    tonnage,
    perExercise: [...measured, ...perExercise.filter((e) => e.pct === null)],
    avgPct,
    weekly,
    muscles,
    weeklySets,
    cardioDays: st.filter((s) => s.cardioMin >= 10).length,
    cardioMin: st.reduce((a, s) => a + (s.cardioMin || 0), 0),
    avgSteps: stepDays.length ? Math.round(mean(stepDays.map((s) => s.steps))) : null,
    bodyweight: bw.length >= 2 ? { from: bw[0].kg, to: bw[bw.length - 1].kg } : null,
    waist: waists.length >= 2 ? { from: waists[0].waist, to: waists[waists.length - 1].waist } : null,
  };
}

const list = (xs) => (xs.length > 1 ? `${xs.slice(0, -1).join(', ')} y ${xs[xs.length - 1]}` : xs[0] ?? '');

// Qué significa el resumen, en frases cortas. tone: good | info | warn
export function reportInsights(r, muscleName = (m) => m) {
  const out = [];
  if (r.avgPct !== null) {
    const p = fmt(Math.abs(r.avgPct));
    if (r.avgPct >= 10) out.push({ tone: 'good', title: 'Gran bloque', text: `Tu fuerza ha subido un ${p} % de media. Es un avance muy claro: el plan te funciona, así que no hace falta cambiar mucho.` });
    else if (r.avgPct >= 3) out.push({ tone: 'good', title: 'Progreso sólido', text: `Tu fuerza ha subido un ${p} % de media. Es el ritmo normal de un bloque bien hecho: vas por buen camino.` });
    else if (r.avgPct >= -2) out.push({ tone: 'info', title: 'Has mantenido', text: 'Tu fuerza está más o menos igual que al empezar. Si vienes de un descanso o has cambiado el rango de repeticiones, es lo normal. Si no, mira abajo qué ejercicios se han parado.' });
    else out.push({ tone: 'warn', title: 'Bloque flojo', text: `Tu fuerza ha bajado un ${p} % de media. Suele deberse a cansancio acumulado, dormir poco o comer poco. Plantéate una semana más suave antes del siguiente bloque.` });
  }

  const best = r.perExercise.find((e) => e.pct !== null && e.pct > 0);
  if (best) out.push({ tone: 'good', title: 'Lo que más ha mejorado', text: `${best.name}: de ${fmt(best.first.kg)} kg × ${best.first.reps} a ${fmt(best.last.kg)} kg × ${best.last.reps} (+${fmt(best.pct)} %).` });

  if (r.adherence !== null) {
    const a = Math.round(r.adherence * 100);
    const did = `Hiciste ${r.sessions} de ${r.planned} entrenos.`;
    if (a >= 90) out.push({ tone: 'good', title: `Constancia: ${a} %`, text: `${did} Ser constante es lo que más influye en los resultados, y lo has cumplido.` });
    else if (a >= 70) out.push({ tone: 'info', title: `Constancia: ${a} %`, text: `${did} Está bien; si recuperas los días que se caen, notarás más progreso.` });
    else out.push({ tone: 'warn', title: `Constancia: ${a} %`, text: `${did} Antes de cambiar ejercicios, lo que más te ayudaría es entrenar con más regularidad. Si 4 días no te cuadran, un plan de 3 puede ir mejor.` });
  }

  const stalled = r.perExercise.filter((e) => e.stalled);
  if (stalled.length) out.push({ tone: 'warn', title: 'Estancados al final', text: `${list(stalled.map((e) => e.name))}: 3 sesiones sin mejorar. En el próximo bloque cambia la variante o el rango de repeticiones.` });

  const down = r.perExercise.filter((e) => e.pct !== null && e.pct < -3 && !e.stalled);
  if (down.length) out.push({ tone: 'warn', title: 'Han bajado', text: `${list(down.map((e) => `${e.name} (${fmt(e.pct)} %)`))}. Revisa la técnica y si los hiciste cansada o con prisas.` });

  const flagged = r.perExercise.filter((e) => !e.replaced && e.flags.some((f) => ['molestia', 'no_siento', 'nausea'].includes(f)));
  if (flagged.length) out.push({ tone: 'warn', title: 'Con molestias o sin sentirlos', text: `${list(flagged.map((e) => e.name))}. Buenos candidatos a cambiar en el próximo bloque.` });

  const low = r.imported ? [] : Object.entries(r.weeklySets).filter(([, v]) => v > 0 && v < 10).map(([m]) => muscleName(m));
  if (low.length) out.push({ tone: 'info', title: 'Pocas series por semana', text: `${list(low)}: menos de 10 series semanales de media. Si quieres que crezcan más, añade 1–2 series o un ejercicio.` });

  if (r.waist) {
    const d = r.waist.to - r.waist.from;
    out.push({ tone: 'info', title: 'Cintura', text: `${d < 0 ? 'Ha bajado' : d > 0 ? 'Ha subido' : 'Sigue igual'}${d ? ` ${fmt(Math.abs(d))} cm` : ''} (de ${fmt(r.waist.from)} a ${fmt(r.waist.to)} cm).` });
  }
  return out;
}
