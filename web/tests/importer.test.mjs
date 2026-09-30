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
  // Series que cambian por semana
  assert.deepEqual(parseSetsReps('Sem 1-2: 2 x 12-15 | Sem 3-4: 3 x 10-12', [1, 2, 3, 4]).setsByWeek, { 1: [2, 2], 2: [2, 2], 3: [3, 3], 4: [3, 3] });
  assert.equal(r.setsByWeek, undefined); // mismas series en todas las semanas
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
    assert.equal(day.subtitle.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, ''),
      BLOCK_3.days[i].subtitle.toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, ''), `Día ${i + 1} título`);
    assert.equal(day.weekday, BLOCK_3.days[i].weekday, `Día ${i + 1} día de la semana`);
    const expected = BLOCK_3.days[i].items.filter((it) => !it.optional);
    assert.deepEqual(day.items.map((it) => it.exerciseId), expected.map((it) => it.exerciseId), `Día ${i + 1}`);
    for (const [j, it] of day.items.entries()) {
      assert.deepEqual(it.sets, expected[j].sets, `${it.exerciseId} series`);
      assert.deepEqual(it.reps, expected[j].reps, `${it.exerciseId} reps`);
    }
  }
  assert.equal(res.newExercises.length, 0);
});

test('el Excel del Bloque 1 de la madre: todo del catálogo, torso lunes/jueves y sin ejercicios por encima del hombro', () => {
  const res = parseBlock(sheetsOf('./fixtures/madre-bloque1.xlsx'), EXERCISE_BY_ID);
  assert.deepEqual(res.weeks, [1, 2, 3, 4]);
  assert.deepEqual(res.warnings, []);
  assert.deepEqual(res.newExercises, []);
  assert.deepEqual(res.days.map((d) => d.weekday), [1, 2, 4, 5]); // lunes, martes, jueves, viernes
  assert.match(res.days[0].subtitle, /^Torso/);
  assert.match(res.days[1].subtitle, /^Pierna/);
  const all = res.days.flatMap((d) => d.items);
  assert.equal(all.length, 24);
  assert.deepEqual(res.days.map((d) => d.items.length), [6, 6, 6, 6]);
  // Los días de torso empiezan con rotación externa y repiten la extensión de tríceps en polea.
  for (const d of [res.days[0], res.days[2]]) {
    assert.equal(d.items[0].exerciseId, 'rotacion_externa_polea');
    assert.ok(d.items.some((it) => it.exerciseId === 'ext_triceps_polea'));
  }
  assert.ok(res.days[3].items.some((it) => it.exerciseId === 'patada_polea'));
  // Una sola fila de remo por día de torso (con 3–4 series al final), el resto 2–3.
  for (const d of [res.days[0], res.days[2]]) assert.equal(d.items.filter((it) => /^remo/.test(it.exerciseId)).length, 1);
  for (const it of all) assert.deepEqual(it.sets, /^remo/.test(it.exerciseId) ? [2, 4] : [2, 3], it.sourceName);
  // Series por semana: 2 en las semanas 1–2 y 3 (o 3–4 en el remo) en las 3–4.
  const row = res.days[0].items.find((it) => it.exerciseId === 'remo_maquina_neutro');
  assert.deepEqual(row.setsByWeek, { 1: [2, 2], 2: [2, 2], 3: [3, 4], 4: [3, 4] });
  const overhead = ['press_militar_mancuernas', 'press_hombro_maquina', 'jalon_supino', 'jalon_prono', 'dominadas_asistidas',
    'elev_lateral_mancuernas', 'elev_lateral_polea', 'elev_frontal_pajaros', 'face_pull', 'ext_triceps_overhead', 'aperturas_polea', 'pec_deck'];
  for (const it of all) assert.ok(!overhead.includes(it.exerciseId), `${it.exerciseId} eleva el brazo`);
});
