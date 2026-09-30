import { test } from 'node:test';
import assert from 'node:assert/strict';
import { blockReport, reportInsights } from '../js/report.js';
import { EXERCISE_BY_ID } from '../js/data/exercises.js';
import { BLOCK_1_2, BLOCK_3 } from '../js/data/blocks.js';
import { HISTORY } from '../js/data/history.js';

test('resumen de las semanas 1–8: fuerza, constancia y sustituidos', () => {
  const r = blockReport({ block: BLOCK_1_2, sessions: HISTORY, exercises: EXERCISE_BY_ID });
  assert.equal(r.sessions, 30);
  assert.equal(r.planned, 32);
  assert.ok(r.imported);
  assert.ok(r.avgPct > 20 && r.avgPct < 50, `media ${r.avgPct}`);
  // Semana 1 es la referencia; la 8 debe estar por encima.
  assert.equal(r.weekly[0].pct, 0);
  assert.ok(r.weekly[r.weekly.length - 1].pct > 20);
  // Ordenado de más a menos mejora; los que no tienen peso al final.
  const measured = r.perExercise.filter((e) => e.pct !== null);
  for (let i = 1; i < measured.length; i++) assert.ok(measured[i - 1].pct >= measured[i].pct);
  assert.equal(r.perExercise.find((e) => e.id === 'puente_banda').pct, null);
  // La búlgara se quitó en la semana 5: sustituida, no "estancada".
  const bulgara = r.perExercise.find((e) => e.id === 'bulgara');
  assert.ok(bulgara.replaced);
  assert.equal(bulgara.stalled, false);

  const ins = reportInsights(r);
  assert.equal(ins[0].title, 'Gran bloque');
  assert.ok(ins.some((i) => i.title.startsWith('Constancia: 94')));
  // Con datos importados (1 serie por semana) no se avisa de poco volumen.
  assert.ok(!ins.some((i) => i.title === 'Pocas series por semana'));
});

test('resumen de un bloque sin entrenos', () => {
  const r = blockReport({ block: BLOCK_3, sessions: HISTORY, exercises: EXERCISE_BY_ID });
  assert.equal(r.sessions, 0);
  assert.equal(r.avgPct, null);
  assert.deepEqual(reportInsights(r).map((i) => i.title), ['Constancia: 0 %']);
});
