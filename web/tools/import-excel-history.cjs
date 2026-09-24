// Convierte el Excel de las semanas 1–8 en web/js/data/history.js.
// Uso: node web/tools/import-excel-history.cjs <ruta/Plan_Entrenamiento_Anebn.xlsx>
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const ctx = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../vendor/xlsx.mini.min.js'), 'utf8'), ctx);
const XLSX = ctx.XLSX;

const file = process.argv[2];
if (!file) {
  console.error('Falta la ruta del Excel');
  process.exit(1);
}

// Nombre de fila en el Excel → id de ejercicio + rango de reps que tenía entonces.
const ROWS = {
  'Dia 1': {
    'Press banca o press inclinado con mancuernas': ['press_mancuernas', [8, 10]],
    'Remo con barra o maquina': ['remo_barra', [8, 10]],
    'Press militar con mancuerna': ['press_militar_mancuernas', [8, 10]],
    'Jalon al pecho': ['jalon_supino', [10, 12]],
    'Elevaciones laterales': ['elev_lateral_mancuernas', [12, 15]],
    'Elevacion lateral en polea': ['elev_lateral_polea', [12, 15]],
    'Extension de triceps en polea': ['ext_triceps_polea', [12, 15]],
    'Press frances con mancuerna': ['press_frances', [12, 15]],
  },
  'Dia 2': {
    'Hip thrust': ['hip_thrust', [8, 10]],
    'Sentadilla bulgara': ['bulgara', [10, 10]],
    'Prensa de piernas (pies altos y separados)': ['prensa_pies_altos', [10, 12]],
    'Peso muerto rumano': ['rdl', [10, 12]],
    'Extension de cuadriceps en maquina': ['ext_cuadriceps', [12, 15]],
    'Sentadilla hack en maquina': ['hack', [10, 12]],
    'Curl femoral en maquina': ['curl_femoral', [12, 15]],
    'Abductores en maquina': ['abductores', [15, 15]],
    'Puente de gluteo con banda elastica en rodillas': ['puente_banda', [15, 20]],
  },
  'Dia 3': {
    'Press inclinado con barra o maquina': ['press_inclinado_barra', [8, 10]],
    'Press inclinado con mancuernas': ['press_inclinado_mancuernas', [8, 10]],
    'Remo con mancuerna a un brazo': ['remo_mancuerna', [8, 10]],
    'Elevacion frontal + posterior (pajaros)': ['elev_frontal_pajaros', [12, 15]],
    'Face pull en polea': ['face_pull', [12, 15]],
    'Jalon al pecho': ['jalon_prono', [10, 12]],
    'Curl de biceps': ['curl_biceps', [10, 12]],
    'Curl martillo con mancuerna': ['curl_martillo', [10, 12]],
    'Fondos en maquina o press cerrado': ['fondos_maquina', [10, 12]],
  },
  'Dia 4': {
    'Zancadas o step up': ['zancadas', [10, 12]],
    'Peso muerto convencional o rumano con mancuernas': ['peso_muerto', [8, 10]],
    'Prensa o sentadilla goblet': ['goblet', [10, 12]],
    'Patada de gluteo en polea': ['patada_polea', [12, 15]],
    'Curl femoral': ['curl_femoral', [12, 15]],
  },
};

// Celdas que no son un registro real (p. ej. el 6 kg de la semana 5 en la extensión
// de tríceps corresponde al primer intento de press francés, que ya tiene su fila).
const SKIP = new Set(['Dia 1|ext_triceps_polea|5']);

const DAY_OFFSET = { 'Dia 1': 0, 'Dia 2': 1, 'Dia 3': 3, 'Dia 4': 4 };
const WEEK1_MONDAY = new Date(Date.UTC(2026, 6, 13)); // semana 8 = 31 ago, luego 2 semanas de descanso

function num(v) {
  if (typeof v === 'number') return v;
  const m = String(v).replace(/'/g, '.').replace(',', '.').match(/^\s*(\d+(?:\.\d+)?)/);
  return m ? parseFloat(m[1]) : null;
}

function rir(v) {
  if (typeof v === 'number') return v;
  const s = String(v);
  const or = s.match(/(\d)\s*o\s*(\d)/);
  if (or) return (parseInt(or[1]) + parseInt(or[2])) / 2;
  return num(s);
}

function note(...cells) {
  // Conserva el texto original de las celdas que no son un número limpio (p. ej. "14(3)", "2(cambiar)").
  return cells
    .map((c) => String(c).trim())
    .filter((s) => s && !/^\d+(?:[.,']\d+)?$/.test(s) && !/^\d\s*o\s*\d$/.test(s) && s !== 'banda' && !/^\d+-\d+-\d+$/.test(s))
    .join(' · ');
}

const U8 = vm.runInNewContext('Uint8Array', ctx);
const wb = XLSX.read(new U8(fs.readFileSync(file)), { type: 'array' });
const sessions = [];

for (const [sheet, rows] of Object.entries(ROWS)) {
  const data = XLSX.utils.sheet_to_json(wb.Sheets[sheet], { header: 1, defval: '' });
  for (let week = 1; week <= 8; week++) {
    const entries = [];
    for (const r of data.slice(4)) {
      const map = rows[String(r[0]).trim()];
      if (!map) continue;
      const [exerciseId, range] = map;
      if (SKIP.has(`${sheet}|${exerciseId}|${week}`)) continue;
      const [kgCell, repsCell, rirCell] = r.slice(4 + (week - 1) * 3, 7 + (week - 1) * 3);
      if ([kgCell, repsCell, rirCell].every((c) => c === '')) continue;
      if (entries.some((e) => e.exerciseId === exerciseId)) continue; // filas resumen repetidas

      let sets;
      const kgStr = String(kgCell);
      if (/^\d+-\d+-\d+$/.test(kgStr.trim())) {
        // "30-25-20" en el puente con banda = reps de cada serie
        sets = kgStr.split('-').map((reps) => ({ kg: 0, reps: +reps, rir: null, done: true }));
      } else {
        sets = [{
          kg: kgStr.trim() === 'banda' ? 0 : num(kgCell),
          reps: num(repsCell),
          rir: rir(rirCell),
          done: true,
        }];
      }
      entries.push({
        exerciseId,
        range,
        sets,
        summary: true,
        note: note(kgCell, rirCell),
        flags: /🤢/.test(String(rirCell)) ? ['nausea'] : [],
      });
    }
    if (!entries.length) continue;
    const d = new Date(WEEK1_MONDAY);
    d.setUTCDate(d.getUTCDate() + (week - 1) * 7 + DAY_OFFSET[sheet]);
    const date = d.toISOString().slice(0, 10);
    sessions.push({
      id: `hist-w${week}-${sheet.replace(' ', '').toLowerCase()}`,
      blockId: 'bloque1_2',
      week,
      dayId: 'd' + sheet.slice(-1),
      date,
      approxDate: true,
      imported: true,
      finished: true,
      entries,
      note: '',
    });
  }
}

sessions.sort((a, b) => a.date.localeCompare(b.date));
const out = path.join(__dirname, '..', 'js', 'data', 'history.js');
fs.writeFileSync(
  out,
  '// Generado por tools/import-excel-history.cjs a partir del Excel de las semanas 1–8.\n' +
    '// Cada ejercicio tiene una sola fila por semana (la serie representativa que anotaste).\n' +
    'export const HISTORY = ' + JSON.stringify(sessions, null, 1) + ';\n'
);
console.log(`${sessions.length} sesiones, ${sessions.reduce((n, s) => n + s.entries.length, 0)} registros → ${out}`);
