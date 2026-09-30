import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EXERCISES } from '../js/data/exercises.js';
import { GUIDES, videoUrl } from '../js/data/guides.js';

test('todos los ejercicios del catálogo tienen ficha completa', () => {
  for (const ex of EXERCISES) {
    const g = GUIDES[ex.id];
    assert.ok(g, `${ex.id} sin ficha`);
    assert.ok(g.works.length > 10, `${ex.id}: works`);
    assert.ok(g.steps.length >= 2, `${ex.id}: steps`);
    assert.ok(g.mistakes.length >= 1, `${ex.id}: mistakes`);
    assert.ok(g.feel, `${ex.id}: feel`);
    assert.ok(g.video, `${ex.id}: video`);
  }
  // Ninguna ficha para un ejercicio que no existe.
  const ids = new Set(EXERCISES.map((e) => e.id));
  for (const id of Object.keys(GUIDES)) assert.ok(ids.has(id), `ficha huérfana: ${id}`);
});

test('el enlace de vídeo es una búsqueda de YouTube bien codificada', () => {
  assert.equal(videoUrl('hip thrust técnica'), 'https://www.youtube.com/results?search_query=hip%20thrust%20t%C3%A9cnica');
});
