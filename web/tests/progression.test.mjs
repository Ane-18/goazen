import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  e1rm, snap, suggest, isStalled, exerciseHistory, plannedVolume, weightTrend, volumeStatus,
} from '../js/progression.js';
import { EXERCISE_BY_ID } from '../js/data/exercises.js';
import { BLOCK_3 } from '../js/data/blocks.js';
import { HISTORY } from '../js/data/history.js';

const h = (date, range, sets) => ({
  date, range,
  entry: { sets: sets.map(([kg, reps, rir]) => ({ kg, reps, rir, done: true })) },
});

test('e1rm usa reps + RIR', () => {
  assert.equal(e1rm(100, 10, 0), 100 * (1 + 10 / 30));
  assert.equal(e1rm(100, 8, 2), e1rm(100, 10, 0));
  assert.equal(e1rm(0, 8, 2), 0);
});

test('snap respeta la rejilla del último peso', () => {
  assert.equal(snap(38, 34.3, 2.5), 36.8);
  assert.equal(snap(13.3, 14, 2, 'down'), 12);
  assert.equal(snap(42.75, 45, 2.5), 42.5);
});

test('sin historial → pide elegir peso', () => {
  const s = suggest({ history: [], range: [8, 10], today: '2026-09-21' });
  assert.equal(s.kind, 'new');
  assert.equal(s.kg, null);
});

test('llegar al máximo del rango en todas las series → sube', () => {
  const s = suggest({ history: [h('2026-09-20', [8, 10], [[40, 10, 2], [40, 10, 1], [40, 10, 1]])], range: [8, 10], inc: 2.5, today: '2026-09-23' });
  assert.equal(s.kind, 'up');
  assert.equal(s.kg, 42.5);
});

test('dentro del rango → mismo peso, +1 rep', () => {
  const s = suggest({ history: [h('2026-09-20', [8, 10], [[40, 9, 1], [40, 8, 1], [40, 8, 0]])], range: [8, 10], inc: 2.5, today: '2026-09-23' });
  assert.equal(s.kind, 'reps');
  assert.equal(s.kg, 40);
  assert.deepEqual(s.reps, [9, 10]);
});

test('RIR ≥ 3 dentro del rango → demasiado fácil, sube', () => {
  const s = suggest({ history: [h('2026-09-20', [12, 15], [[4, 12, 3], [4, 12, 3], [4, 12, 4]])], range: [12, 15], inc: 1, today: '2026-09-23' });
  assert.equal(s.kind, 'up');
  assert.equal(s.kg, 5);
});

test('por debajo del rango una vez → repite; dos veces → baja', () => {
  const once = suggest({ history: [h('2026-09-20', [8, 10], [[45, 6, 0]])], range: [8, 10], inc: 2.5, today: '2026-09-23' });
  assert.equal(once.kind, 'hold');
  const twice = suggest({
    history: [h('2026-09-20', [8, 10], [[45, 6, 0]]), h('2026-09-17', [8, 10], [[45, 7, 0]])],
    range: [8, 10], inc: 2.5, today: '2026-09-23',
  });
  assert.equal(twice.kind, 'down');
  assert.equal(twice.kg, 42.5);
});

test('usa la siguiente placa conocida de la máquina', () => {
  const s = suggest({
    history: [h('2026-09-20', [12, 15], [[35.4, 15, 1]]), h('2026-09-01', [12, 15], [[37.6, 10, 0]])],
    range: [12, 15], inc: 2.5, today: '2026-09-23',
  });
  assert.equal(s.kg, 37.6);
});

test('cambio de rango 8–10 → 6–8 estima un peso mayor', () => {
  const s = suggest({ history: [h('2026-09-20', [8, 10], [[45, 8, 1]])], range: [6, 8], rir: [1, 2], inc: 2.5, today: '2026-09-23' });
  assert.equal(s.kind, 'range');
  assert.ok(s.kg >= 45, `esperaba ≥45, fue ${s.kg}`);
});

test('tras ≥14 días sin el ejercicio → primera sesión algo más ligera', () => {
  const s = suggest({ history: [h('2026-09-01', [8, 10], [[45, 9, 1]])], range: [8, 10], inc: 2.5, today: '2026-09-22' });
  assert.equal(s.kind, 'return');
  assert.equal(s.kg, 42.5);
});

test('estancamiento: 3 sesiones sin mejorar el 1RM estimado', () => {
  const flat = [4, 4, 4].map((kg, i) => h(`2026-09-0${4 - i}`, [12, 15], [[kg, 12, 1]]));
  assert.equal(isStalled(flat), true);
  const rising = [7, 6, 5, 4].map((kg, i) => h(`2026-09-0${4 - i}`, [12, 15], [[kg, 12, 1]]));
  assert.equal(isStalled(rising), false);
});

test('historial real: la extensión de tríceps se estancó y las laterales con mancuerna también', () => {
  const lat = exerciseHistory(HISTORY, 'elev_lateral_mancuernas');
  assert.equal(lat.length, 4);
  assert.equal(isStalled(lat), false); // la última (4 × 15) mejoró las reps
  const fondos = exerciseHistory(HISTORY, 'fondos_maquina');
  assert.equal(isStalled(fondos), true); // 32 kg tres semanas: motivo del cambio en el bloque 3
});

test('historial real: sugerencias de la semana 9 salen coherentes', () => {
  const today = '2026-09-22';
  for (const day of BLOCK_3.days) {
    for (const it of day.items) {
      const ex = EXERCISE_BY_ID[it.exerciseId];
      assert.ok(ex, `falta el ejercicio ${it.exerciseId}`);
      const s = suggest({
        history: exerciseHistory(HISTORY, it.exerciseId),
        range: it.reps[9], rir: BLOCK_3.rir, inc: ex.inc, today, loadless: ['banda', 'corporal'].includes(ex.equip),
      });
      if (s.kg !== null && s.kg !== undefined) assert.ok(s.kg >= 0 && s.kg < 200, `${it.exerciseId}: ${s.kg}`);
      assert.ok(s.text.length > 10);
    }
  }
  const ht = suggest({ history: exerciseHistory(HISTORY, 'hip_thrust'), range: [6, 8], rir: [1, 2], inc: 2.5, today });
  assert.equal(ht.kind, 'return');
  assert.ok(ht.kg >= 40 && ht.kg <= 47.5, `hip thrust ${ht.kg}`);
});

test('volumen planificado del bloque 3: pecho y hombro lateral por debajo de 10', () => {
  const { min, max } = plannedVolume(BLOCK_3, EXERCISE_BY_ID);
  assert.equal(min.pecho, 6);
  assert.equal(max.pecho, 8);
  assert.equal(min.hombro_lat, 4.5);
  assert.equal(volumeStatus(min.hombro_lat), 'low');
  assert.ok(min.gluteo > 20);
  assert.ok(min.espalda >= 12);
});

test('tendencia de peso: media 7 días y ritmo semanal', () => {
  const entries = [];
  for (let i = 0; i < 21; i++) {
    const d = new Date(Date.UTC(2026, 8, 1 + i)).toISOString().slice(0, 10);
    entries.push({ date: d, kg: 64 - i * 0.05 });
  }
  const { points, ratePct } = weightTrend(entries);
  assert.equal(points.length, 21);
  assert.ok(ratePct < -0.5 && ratePct > -0.6, `ritmo ${ratePct}`);
});
