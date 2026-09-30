import { test } from 'node:test';
import assert from 'node:assert/strict';
import { initialState, migrate } from '../js/store.js';
import { EXERCISE_BY_ID } from '../js/data/exercises.js';

test('perfil nuevo: Bloque 1 desde el 19 de octubre, sin historial de Ane', () => {
  const s = initialState('nuevo', 'Miren');
  assert.deepEqual(s.profile, { kind: 'nuevo', name: 'Miren' });
  assert.equal(s.sessions.length, 0);
  assert.equal(s.blocks.length, 1);
  const b = s.blocks[0];
  assert.equal(s.activeBlockId, b.id);
  assert.equal(b.startDate, '2026-10-19');
  assert.deepEqual(b.rir, [2, 3]);
  assert.deepEqual(b.days.map((d) => d.weekday), [1, 2, 4, 5]);
  for (const d of b.days) for (const it of d.items) assert.ok(EXERCISE_BY_ID[it.exerciseId], it.exerciseId);
  assert.equal(s.settings.stepsGoal, 8000);
});

test('datos guardados antes de los perfiles → siguen siendo de Ane, sin cambios', () => {
  const ane = initialState('ane');
  delete ane.profile;
  ane.settings.stepsGoal = 12000; // un ajuste suyo
  const m = migrate(JSON.parse(JSON.stringify(ane)));
  assert.deepEqual(m.profile, { kind: 'ane', name: 'Ane' });
  assert.equal(m.settings.stepsGoal, 12000);
  assert.equal(m.sessions.length, ane.sessions.length);
  assert.equal(m.activeBlockId, 'bloque3');
});

test('una copia del perfil nuevo no se mezcla con los datos de Ane', () => {
  const s = JSON.parse(JSON.stringify(initialState('nuevo', 'Miren')));
  const m = migrate(s);
  assert.equal(m.profile.name, 'Miren');
  assert.equal(m.sessions.length, 0);
  assert.ok(!m.blocks.some((b) => b.id === 'bloque3'));
});
