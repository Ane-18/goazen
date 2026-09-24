// Exportar a Excel (mismo formato que tus hojas) y copia de seguridad en JSON.
import * as store from './store.js';
import { workingSets, bestSet, round1 } from './progression.js';

let xlsxLoading = null;
export function loadXlsx() {
  if (window.XLSX) return Promise.resolve(window.XLSX);
  xlsxLoading ??= new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = 'vendor/xlsx.mini.min.js';
    s.onload = () => resolve(window.XLSX);
    s.onerror = reject;
    document.head.appendChild(s);
  });
  return xlsxLoading;
}

function download(name, blob) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
}

export async function exportExcel() {
  const XLSX = await loadXlsx();
  const st = store.get();
  const ex = store.exercises();
  const wb = XLSX.utils.book_new();
  const name = (id) => ex[id]?.name ?? id;

  // Una hoja por día del bloque activo, con columnas por semana como en tu Excel.
  const block = store.activeBlock();
  for (const day of block.days) {
    const header1 = ['Ejercicio', 'Series', 'Reps'];
    const header2 = ['', '', ''];
    for (const w of block.weeks) { header1.push(`SEMANA ${w}`, '', ''); header2.push('Peso (kg)', 'Reps', 'RIR'); }
    const rows = [[`${block.name} · ${day.name}`], [day.subtitle], header1, header2];
    for (const it of day.items) {
      const row = [name(it.exerciseId), `${it.sets[0]}${it.sets[1] !== it.sets[0] ? '-' + it.sets[1] : ''}`,
        block.weeks.map((w) => it.reps[w]?.join('-')).filter((v, i, a) => a.indexOf(v) === i).join(' / ')];
      for (const w of block.weeks) {
        const s = store.sessionFor(block.id, w, day.id);
        const entry = s?.finished && s.entries.find((e) => e.exerciseId === it.exerciseId);
        const b = entry && bestSet(entry);
        row.push(b ? b.kg : '', b ? b.reps : '', b && Number.isFinite(b.rir) ? b.rir : '');
      }
      rows.push(row);
    }
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(rows), day.name.slice(0, 31));
  }

  // Todas las series de todas las sesiones.
  const all = [['Fecha', 'Bloque', 'Semana', 'Día', 'Ejercicio', 'Serie', 'Peso (kg)', 'Reps', 'RIR', 'Nota', 'Sensaciones']];
  for (const s of [...st.sessions].filter((x) => x.finished).sort((a, b) => a.date.localeCompare(b.date))) {
    const blockName = store.blockById(s.blockId)?.name ?? s.blockId;
    for (const e of s.entries) {
      workingSets(e).forEach((set, i) => {
        all.push([s.date + (s.approxDate ? ' (aprox.)' : ''), blockName, s.week, s.dayId.replace('d', 'Día '), name(e.exerciseId),
          i + 1, set.kg, set.reps, set.rir ?? '', i === 0 ? e.note ?? '' : '', i === 0 ? (e.flags ?? []).join(', ') : '']);
      });
    }
  }
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(all), 'Todas las series');

  const bw = [['Fecha', 'Peso (kg)'], ...[...st.bodyweight].sort((a, b) => a.date.localeCompare(b.date)).map((b) => [b.date, round1(b.kg)])];
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(bw), 'Peso corporal');

  const steps = [['Fecha', 'Pasos', 'Cardio (min)'], ...[...st.steps].sort((a, b) => a.date.localeCompare(b.date)).map((s) => [s.date, s.steps ?? '', s.cardioMin ?? ''])];
  XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(steps), 'Cardio y pasos');

  const out = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
  download(`goazen-${store.today()}.xlsx`, new Blob([out], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }));
}

export function exportBackup() {
  const blob = new Blob([JSON.stringify(store.get(), null, 1)], { type: 'application/json' });
  download(`goazen-copia-${store.today()}.json`, blob);
}

export async function importBackup(file) {
  const data = JSON.parse(await file.text());
  if (!data || !Array.isArray(data.sessions) || !Array.isArray(data.blocks)) {
    throw new Error('El archivo no parece una copia de Goazen.');
  }
  store.replaceAll(data);
}
