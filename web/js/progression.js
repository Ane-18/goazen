// Lógica de entrenamiento: sugerencia de carga, estancamiento y volumen semanal.
// Funciones puras (sin DOM ni almacenamiento) para poder probarlas con `node --test`.
//
// Base científica (ver también la pantalla "Ciencia"):
// - Doble progresión: subir reps dentro del rango y, al llegar arriba, subir carga.
//   Plotkin et al. 2022: progresar por carga o por repeticiones produce hipertrofia similar.
// - RIR (repeticiones en reserva) para autorregular: Zourdos et al. 2016, Helms et al. 2016.
//   Entrenar a 0–3 RIR produce hipertrofia similar a ir al fallo (Refalo et al. 2023).
// - Estimación de 1RM con Epley ajustada por RIR: reps hasta el fallo = reps + RIR.
// - Volumen: ≥10 series semanales por músculo (Schoenfeld et al. 2017), con series
//   indirectas contadas como 0,5 (Pelland et al. 2024).

export const DAY_MS = 86400000;

export function e1rm(kg, reps, rir) {
  if (!(kg > 0) || !(reps > 0)) return 0;
  const r = Number.isFinite(rir) ? rir : 2;
  return kg * (1 + (reps + r) / 30);
}

export function weightFor(oneRm, reps, rir) {
  return oneRm / (1 + (reps + rir) / 30);
}

// Redondea a la rejilla de pesos que parte del último peso usado (así respeta las
// placas raras de las máquinas: 34,3 → 36,6 …).
export function snap(weight, anchor, inc, mode = 'nearest') {
  if (!(inc > 0)) return round1(weight);
  const steps = (weight - anchor) / inc;
  const k = mode === 'down' ? Math.floor(steps + 1e-9) : Math.round(steps);
  return round1(anchor + k * inc);
}

export const round1 = (x) => Math.round(x * 10) / 10;

export function workingSets(entry) {
  return (entry?.sets ?? []).filter((s) => s.done && s.reps > 0);
}

export function bestSet(entry) {
  let best = null;
  for (const s of workingSets(entry)) {
    const v = e1rm(s.kg, s.reps, s.rir);
    if (!best || v > best.e1rm || (v === best.e1rm && s.kg > best.kg)) best = { ...s, e1rm: v };
  }
  return best;
}

export function topWeight(entry) {
  return Math.max(0, ...workingSets(entry).map((s) => s.kg || 0));
}

// Historial de un ejercicio: [{ date, range, entry }] de la más reciente a la más antigua.
export function exerciseHistory(sessions, exerciseId) {
  const out = [];
  for (const s of sessions) {
    if (!s.finished) continue;
    for (const entry of s.entries) {
      if (entry.exerciseId === exerciseId && workingSets(entry).length) {
        out.push({ date: s.date, week: s.week, blockId: s.blockId, range: entry.range, entry, session: s });
      }
    }
  }
  return out.sort((a, b) => b.date.localeCompare(a.date));
}

function daysBetween(a, b) {
  return Math.round((Date.parse(b) - Date.parse(a)) / DAY_MS);
}

function nextKnownWeight(history, current, inc) {
  // Si ya usaste un peso algo mayor en este ejercicio (p. ej. la siguiente placa de la
  // máquina), úsalo en vez de sumar el incremento teórico.
  const known = new Set();
  for (const h of history) for (const s of workingSets(h.entry)) if (s.kg > current) known.add(s.kg);
  const candidates = [...known].filter((k) => k <= current + inc * 1.5).sort((a, b) => a - b);
  return candidates[0] ?? round1(current + inc);
}

/**
 * Sugerencia para la próxima sesión de un ejercicio.
 * @param {object} p
 * @param {Array} p.history  exerciseHistory(...) de este ejercicio
 * @param {[number, number]} p.range  rango de reps de hoy
 * @param {[number, number]} p.rir  RIR objetivo [min, max]
 * @param {number} p.inc  incremento de carga
 * @param {string} p.today  fecha ISO (yyyy-mm-dd)
 * @param {boolean} p.loadless  ejercicio sin carga (banda / peso corporal)
 */
export function suggest({ history, range, rir = [1, 2], inc = 2.5, today, loadless = false }) {
  const [lo, hi] = range;
  if (!history.length) {
    return {
      kind: 'new',
      kg: null,
      reps: [lo, hi],
      text: `Elige un peso con el que hagas ${lo}–${hi} reps y te queden ${rir[0]}–${rir[1]} más en reserva.`,
      short: SHORT.new,
    };
  }

  const last = history[0];
  const sets = workingSets(last.entry);
  const top = topWeight(last.entry);
  const atTop = sets.filter((s) => (s.kg || 0) === top);
  const minReps = Math.min(...atTop.map((s) => s.reps));
  const rirs = atTop.map((s) => s.rir).filter(Number.isFinite);
  const minRir = rirs.length ? Math.min(...rirs) : null;
  const gap = today ? daysBetween(last.date, today) : 0;

  let res;
  if (loadless || !(top > 0)) {
    res = minReps >= hi
      ? { kind: 'up', kg: top || null, reps: [lo, hi], text: `Llegaste a ${hi} reps: añade resistencia (banda más dura, pausa arriba o más lento).` }
      : { kind: 'reps', kg: top || null, reps: [Math.min(minReps + 1, hi), hi], text: `Intenta 1–2 reps más por serie que la última vez (${minReps}).` };
  } else if (last.range && Math.abs(last.range[0] - lo) >= 2) {
    // Cambio de rango de repeticiones (p. ej. 8–10 → 6–8): estimar el peso por 1RM.
    const b = bestSet(last.entry);
    const target = weightFor(b.e1rm, lo, rir[1]);
    const kg = Math.max(inc || 0.5, snap(target, top, inc, 'down'));
    res = {
      kind: 'range',
      kg,
      reps: [lo, hi],
      text: `Antes hacías ${last.range[0]}–${last.range[1]} reps y ahora ${lo}–${hi}: calculado a partir de tu ${fmt(b.kg)} kg × ${b.reps}. Si la primera serie es muy fácil o muy dura, ajusta.`,
    };
  } else if (minReps >= hi || (minReps >= lo && minRir !== null && minRir >= 3)) {
    const kg = nextKnownWeight(history, top, inc);
    res = {
      kind: 'up',
      kg,
      reps: [lo, hi],
      text: minReps >= hi
        ? `Completaste ${hi} reps con ${fmt(top)} kg: sube a ${fmt(kg)} kg y vuelve a ${lo} reps.`
        : `Te sobraron ${fmt(minRir)} reps en reserva: sube a ${fmt(kg)} kg.`,
    };
  } else if (minReps >= lo) {
    res = {
      kind: 'reps',
      kg: top,
      reps: [Math.min(minReps + 1, hi), hi],
      text: `Mantén ${fmt(top)} kg e intenta ${Math.min(minReps + 1, hi)} reps (última vez ${minReps}). Al llegar a ${hi} en todas las series, sube.`,
    };
  } else {
    const prev = history[1];
    const prevShort = prev && topWeight(prev.entry) === top && Math.min(...workingSets(prev.entry).filter((s) => s.kg === top).map((s) => s.reps)) < lo;
    res = prevShort
      ? { kind: 'down', kg: Math.max(inc, round1(top - inc)), reps: [lo, hi], text: `Dos sesiones sin llegar a ${lo} reps con ${fmt(top)} kg: baja a ${fmt(round1(top - inc))} kg y reconstruye.` }
      : { kind: 'hold', kg: top, reps: [lo, hi], text: `No llegaste a ${lo} reps (${minReps}). Repite ${fmt(top)} kg; si vuelve a pasar, bajamos.` };
  }

  if (gap >= 14 && res.kg > 0 && !loadless) {
    // Tras ≥2 semanas sin ese ejercicio: primera sesión algo más ligera (readaptación);
    // tras ≥4 semanas, un poco más.
    const factor = gap >= 28 ? 0.9 : 0.95;
    const kg = Math.max(inc || 0.5, snap(res.kg * factor, top, inc, 'nearest'));
    res = {
      ...res,
      kind: 'return',
      kg,
      text: `Llevas ${gap} días sin hacerlo, así que empieza algo más suave. En 1–2 sesiones vuelves a tu nivel.${res.kind === 'range' ? ' Además esta semana tocan menos reps con más peso.' : ''}`,
    };
  }
  return { ...res, short: SHORT[res.kind] };
}

export const SHORT = {
  new: 'Primera vez: elige un peso cómodo',
  up: 'Sube peso',
  reps: 'Mismo peso, intenta 1 rep más',
  hold: 'Repite el mismo peso',
  down: 'Baja un poco el peso',
  range: 'Menos reps, más peso',
  return: 'Vuelta tras el descanso: algo más suave',
};

// Estancado = en las últimas `n` sesiones no has superado la primera de ellas ni en peso
// ni en repeticiones. Solo cuenta el rendimiento (kg × reps), no el RIR anotado.
export function isStalled(history, n = 3) {
  if (history.length < n) return false;
  const perf = (h) => Math.max(0, ...workingSets(h.entry).map((s) => e1rm(s.kg, s.reps, 0)));
  const base = perf(history[n - 1]);
  const recent = history.slice(0, n - 1).map(perf);
  return base > 0 && Math.max(...recent) <= base * 1.005;
}

// Series semanales por músculo. Principal = 1, secundario = 0,5.
export function addMuscleSets(acc, exercise, sets) {
  if (!exercise || !(sets > 0)) return acc;
  for (const m of exercise.muscles.p) acc[m] = (acc[m] ?? 0) + sets;
  for (const m of exercise.muscles.s) acc[m] = (acc[m] ?? 0) + sets * 0.5;
  return acc;
}

export function plannedVolume(block, exercises, { includeOptional = false } = {}) {
  const min = {};
  const max = {};
  for (const day of block.days) {
    for (const it of day.items) {
      if (it.optional && !includeOptional) continue;
      addMuscleSets(min, exercises[it.exerciseId], it.sets[0]);
      addMuscleSets(max, exercises[it.exerciseId], it.sets[1]);
    }
  }
  return { min, max };
}

export function doneVolume(sessions, exercises) {
  const acc = {};
  for (const s of sessions) for (const e of s.entries) addMuscleSets(acc, exercises[e.exerciseId], workingSets(e).length);
  return acc;
}

export function volumeStatus(sets) {
  if (sets < 6) return 'low';
  if (sets < 10) return 'fair';
  if (sets <= 20) return 'good';
  return 'high';
}

// Media móvil de 7 días y ritmo semanal en % del peso corporal.
export function weightTrend(entries) {
  const sorted = [...entries].filter((e) => e.kg > 0).sort((a, b) => a.date.localeCompare(b.date));
  const points = sorted.map((e) => {
    const from = Date.parse(e.date) - 6 * DAY_MS;
    const win = sorted.filter((x) => Date.parse(x.date) >= from && Date.parse(x.date) <= Date.parse(e.date));
    return { date: e.date, kg: e.kg, avg: win.reduce((a, x) => a + x.kg, 0) / win.length };
  });
  let ratePct = null;
  if (points.length >= 2) {
    const last = points[points.length - 1];
    const ref = [...points].reverse().find((p) => daysBetween(p.date, last.date) >= 7);
    if (ref) {
      const weeks = daysBetween(ref.date, last.date) / 7;
      ratePct = ((last.avg - ref.avg) / ref.avg / weeks) * 100;
    }
  }
  return { points, ratePct };
}

export function fmt(x) {
  if (x === null || x === undefined || Number.isNaN(x)) return '–';
  return String(round1(x)).replace('.', ',');
}
