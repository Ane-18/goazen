// Convierte un Excel de plan (hojas "Dia 1"…"Dia N") en un bloque listo para la app.
// Uso: node web/tools/import-block.cjs <excel> <salida.js> <NOMBRE_EXPORT> <id> "<nombre>" <inicio yyyy-mm-dd> <rirMin> <rirMax> ["descripción"]
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const [file, out, exportName, id, name, startDate, rirMin, rirMax, description = ''] = process.argv.slice(2);
if (!rirMax) {
  console.error('Faltan argumentos. Mira el comentario de la primera línea.');
  process.exit(1);
}

const ctx = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../vendor/xlsx.mini.min.js'), 'utf8'), ctx);
const XLSX = ctx.XLSX;
const wb = XLSX.read(fs.readFileSync(file), { type: 'buffer' });
const sheets = JSON.parse(JSON.stringify(Object.fromEntries(wb.SheetNames.map((n) => [n, XLSX.utils.sheet_to_json(wb.Sheets[n], { header: 1, defval: '' })]))));

(async () => {
  const { parseBlock } = await import(path.join(__dirname, '../js/importer.js').replace(/\\/g, '/').replace(/^/, 'file:///'));
  const { EXERCISE_BY_ID } = await import(path.join(__dirname, '../js/data/exercises.js').replace(/\\/g, '/').replace(/^/, 'file:///'));
  const res = parseBlock(sheets, EXERCISE_BY_ID);
  if (res.warnings.length || res.newExercises.length) {
    console.error('Avisos:', res.warnings, 'Ejercicios fuera del catálogo:', res.newExercises.map((e) => e.name));
    process.exit(1);
  }
  const block = {
    id,
    name,
    weeks: res.weeks,
    startDate,
    rir: [Number(rirMin), Number(rirMax)],
    description,
    days: res.days.map((d) => ({ ...d, items: d.items.map(({ sourceName, ...it }) => it) })),
    changes: [],
  };
  fs.writeFileSync(out, `// Generado por tools/import-block.cjs a partir de ${path.basename(file)}. No editar a mano.\nexport const ${exportName} = ${JSON.stringify(block, null, 1)};\n`);
  console.log(`ok: ${block.days.length} días, ${block.days.reduce((n, d) => n + d.items.length, 0)} ejercicios → ${out}`);
})();
