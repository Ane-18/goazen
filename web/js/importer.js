// Importa un bloque desde un Excel con el formato de tus planes:
// hojas "Dia 1", "Dia 2"… con columnas Ejercicio | Foto | Series x Reps | Agarre / nota | SEMANA N…
// La parte de interpretar filas es pura (sin DOM) para poder probarla con node.

const norm = (s) =>
  String(s ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[^a-z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const STOP = new Set(['de', 'en', 'con', 'el', 'la', 'al', 'a', 'o', 'y', 'un', 'una', 'por', 'los', 'las']);
const tokens = (s) => new Set(norm(s).split(' ').filter((t) => t && !STOP.has(t)));

// Nombres alternativos que aparecen en tus Excel.
const ALIASES = {
  press_mancuernas: ['press banca o press inclinado con mancuernas', 'press banca con mancuernas'],
  jalon_supino: ['jalon al pecho agarre supino'],
  jalon_prono: ['jalon al pecho agarre prono ancho'],
  curl_femoral: ['curl femoral', 'curl femoral en maquina'],
  hip_thrust: ['hip thrust'],
  rdl: ['peso muerto rumano'],
  elev_lateral_polea: ['elevacion lateral en polea', 'elevaciones laterales en polea'],
};

export function matchExercise(name, exercises, note = '') {
  const n = norm(name);
  for (const [id, names] of Object.entries(ALIASES)) if (names.includes(n) && exercises[id]) return { id, score: 1 };
  const t = tokens(name);
  const scored = Object.values(exercises).map((ex) => {
    const u = tokens(ex.name);
    const inter = [...t].filter((x) => u.has(x)).length;
    // Parecido global, o 0,85 si todas las palabras del Excel están en el nombre del catálogo.
    const covered = t.size >= 2 && inter === t.size ? 0.85 : 0;
    return { id: ex.id, ex, score: norm(ex.name) === n ? 1 : Math.max(covered, inter / Math.max(t.size, u.size)) };
  }).sort((a, b) => b.score - a.score);
  const best = scored[0];
  if (!best || best.score < 0.6) return null;
  // Empate (p. ej. dos "Jalón al pecho"): decide la nota (agarre supino / prono…).
  const tied = scored.filter((c) => c.score >= best.score - 0.05);
  if (tied.length > 1 && note) {
    const nt = tokens(note);
    const extra = (c) => [...tokens(c.ex.name + ' ' + (c.ex.cue ?? ''))].filter((x) => nt.has(x) && !t.has(x)).length;
    tied.sort((a, b) => extra(b) - extra(a) || b.score - a.score);
    return { id: tied[0].id, score: tied[0].score };
  }
  return { id: best.id, score: best.score };
}

// Músculo principal aproximado para ejercicios que no están en el catálogo.
export function guessMuscles(name) {
  const n = norm(name);
  const rules = [
    [/abdominal|crunch|plancha|rueda|elevacion de piernas/, 'abdomen'],
    [/face pull|pajaro|posterior/, 'hombro_post'],
    [/lateral/, 'hombro_lat'],
    [/militar|hombro|frontal/, 'hombro_ant'],
    [/femoral|nordico/, 'isquios'],
    [/triceps|frances|fondos|patada de triceps/, 'triceps'],
    [/curl|biceps/, 'biceps'],
    [/press|pecho|aperturas|contractor/, 'pecho'],
    [/remo|jalon|dominada|pullover/, 'espalda'],
    [/hip thrust|gluteo|puente|abduc|patada/, 'gluteo'],
    [/peso muerto|rumano|buenos dias/, 'isquios'],
    [/sentadilla|prensa|zancada|hack|cuadriceps|step|goblet|bulgara/, 'cuadriceps'],
  ];
  const hit = rules.find(([re]) => re.test(n));
  return { p: [hit ? hit[1] : 'gluteo'], s: [] };
}

function guessEquip(name) {
  const n = norm(name);
  if (/polea|cuerda|jalon|face pull/.test(n)) return 'polea';
  if (/maquina|prensa|hack/.test(n)) return 'maquina';
  if (/mancuerna|goblet/.test(n)) return 'mancuerna';
  if (/barra|hip thrust/.test(n)) return 'barra';
  if (/banda/.test(n)) return 'banda';
  if (/plancha|elevacion de piernas|rueda/.test(n)) return 'corporal';
  return 'maquina';
}

// "3-4 x 8-10", "Sem 9-10: 3-4 x 6-8 | Sem 11-12: 3-4 x 10-12", "3 x 10 (por pierna)"
export function parseSetsReps(text, weeks) {
  const re = /(?:sem(?:ana)?s?\s*(\d+)(?:\s*-\s*(\d+))?\s*:\s*)?(\d+)(?:\s*-\s*(\d+))?\s*x\s*(\d+)(?:\s*-\s*(\d+))?/gi;
  const parts = [...String(text ?? '').matchAll(re)];
  if (!parts.length) return null;
  const sets = [Number(parts[0][3]), Number(parts[0][4] ?? parts[0][3])];
  const reps = {};
  for (const w of weeks) reps[w] = [Number(parts[0][5]), Number(parts[0][6] ?? parts[0][5])];
  for (const m of parts) {
    if (!m[1]) continue;
    const from = Number(m[1]);
    const to = Number(m[2] ?? m[1]);
    for (const w of weeks) if (w >= from && w <= to) reps[w] = [Number(m[5]), Number(m[6] ?? m[5])];
  }
  return { sets, reps };
}

const cap = (s) => String(s ?? '').trim().replace(/^\w/, (c) => c.toUpperCase());

/**
 * @param {Object<string, any[][]>} sheets  nombre de hoja → filas (arrays)
 * @param {Object} exercises  catálogo { id: ejercicio }
 * @returns {{ weeks:number[], days:Array, newExercises:Array, warnings:string[] }}
 */
export function parseBlock(sheets, exercises, defaultWeeks = [1, 2, 3, 4]) {
  const days = [];
  const newExercises = [];
  const warnings = [];
  let weeks = [];

  const dayNames = Object.keys(sheets)
    .map((n) => ({ n, m: norm(n).match(/^dia (\d+)/) }))
    .filter((x) => x.m)
    .sort((a, b) => Number(a.m[1]) - Number(b.m[1]));

  for (const { n, m } of dayNames) {
    const rows = sheets[n];
    const h = rows.findIndex((r) => norm(r[0]) === 'ejercicio');
    if (h === -1) { warnings.push(`${n}: no encuentro la fila "Ejercicio".`); continue; }
    const w = rows[h].map((c) => String(c).match(/semana\s*(\d+)/i)).filter(Boolean).map((x) => Number(x[1]));
    if (w.length && !weeks.length) weeks = w;
    const title = rows.slice(0, h).map((r) => r[0]).filter(Boolean);

    const items = [];
    for (const r of rows.slice(h + 1)) {
      const name = String(r[0] ?? '').trim();
      const first = norm(name);
      if (/^(rellena|la columna)/.test(first)) break;
      if (!name || !String(r[2] ?? '').trim()) continue;
      const note = String(r[3] ?? '').trim();
      if (/^sustituid/i.test(note)) continue; // filas antiguas ya sustituidas
      const sr = parseSetsReps(r[2], weeks.length ? weeks : defaultWeeks);
      if (!sr) { warnings.push(`${n}: no entiendo las series de "${name}" (${r[2]}).`); continue; }

      let match = matchExercise(name, { ...exercises, ...Object.fromEntries(newExercises.map((e) => [e.id, e])) }, note);
      if (!match) {
        const ex = {
          id: 'custom_' + norm(name).replace(/ /g, '_').slice(0, 40),
          name: cap(name),
          equip: guessEquip(name),
          muscles: guessMuscles(name),
          inc: 2.5,
          compound: false,
          cue: '',
          custom: true,
        };
        newExercises.push(ex);
        match = { id: ex.id, score: 0 };
      }
      items.push({
        exerciseId: match.id,
        sets: sr.sets,
        reps: sr.reps,
        note,
        optional: /opcional/i.test(note),
        sourceName: name,
      });
    }
    days.push({ id: 'd' + m[1], name: `Día ${m[1]}`, subtitle: cap(title[1] ?? ''), items });
  }

  if (!days.length) warnings.push('No encuentro hojas llamadas "Dia 1", "Dia 2"…');
  // Rellenar semanas si el Excel no las tenía.
  if (!weeks.length) weeks = defaultWeeks;
  return { weeks, days, newExercises, warnings };
}
