import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { parseBlock, parseSetsReps, matchExercise } from '../js/importer.js';
import { EXERCISE_BY_ID } from '../js/data/exercises.js';
import { BLOCK_3 } from '../js/data/blocks.js';

// La librería es un script de navegador: la ejecutamos en un contexto aislado.
const ctx = {};
vm.runInNewContext(readFileSync(new URL('../vendor/xlsx.mini.min.js', import.meta.url), 'utf8'), ctx);
const XLSX = ctx.XLSX;
const U8 = vm.runInNewContext('Uint8Array', ctx); // bytes del mismo contexto: lectura rápida

function sheetsOf(path) {
  const wb = XLSX.read(new U8(readFileSync(new URL(path, import.meta.url))), { type: 'array' });
  return JSON.parse(JSON.stringify(Object.fromEntries(wb.SheetNames.map((n) => [n, XLSX.utils.sheet_to_json(wb.Sheets[n], { header: 1, defval: '' })]))));
}

test('parseSetsReps: rango simple y por semanas', () => {
  assert.deepEqual(parseSetsReps('3-4 x 8-10', [1, 2]), { sets: [3, 4], reps: { 1: [8, 10], 2: [8, 10] } });
  assert.deepEqual(parseSetsReps('3 x 10 (por pierna)', [1]), { sets: [3, 3], reps: { 1: [10, 10] } });
  const r = parseSetsReps('Sem 9-10: 3-4 x 6-8 | Sem 11-12: 3-4 x 10-12', [9, 10, 11, 12]);
  assert.deepEqual(r.reps, { 9: [6, 8], 10: [6, 8], 11: [10, 12], 12: [10, 12] });
  assert.equal(parseSetsReps('sin datos', [1]), null);
});

test('reconoce nombres del catálogo', () => {
  assert.equal(matchExercise('Curl martillo con mancuerna', EXERCISE_BY_ID).id, 'curl_martillo');
  assert.equal(matchExercise('Extension de triceps en polea con cuerda', EXERCISE_BY_ID).id, 'ext_triceps_cuerda');
  assert.equal(matchExercise('Sentadilla con salto al cajón', EXERCISE_BY_ID), null);
});

test('el Excel del Bloque 3 se importa igual que el bloque cargado a mano', () => {
  const res = parseBlock(sheetsOf('./fixtures/bloque3.xlsx'), EXERCISE_BY_ID);
  assert.deepEqual(res.weeks, [9, 10, 11, 12]);
  assert.equal(res.days.length, 4);
  assert.deepEqual(res.warnings, []);
  for (const [i, day] of res.days.entries()) {
    const expected = BLOCK_3.days[i].items.filter((it) => !it.optional);
    assert.deepEqual(day.items.map((it) => it.exerciseId), expected.map((it) => it.exerciseId), `Día ${i + 1}`);
    for (const [j, it] of day.items.entries()) {
      assert.deepEqual(it.sets, expected[j].sets, `${it.exerciseId} series`);
      assert.deepEqual(it.reps, expected[j].reps, `${it.exerciseId} reps`);
    }
  }
  assert.equal(res.newExercises.length, 0);
});
