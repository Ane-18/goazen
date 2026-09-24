// Estado de la app guardado en el propio móvil (localStorage). Nada sale del dispositivo.
import { EXERCISES } from './data/exercises.js';
import { BLOCK_1_2, BLOCK_3 } from './data/blocks.js';
import { HISTORY } from './data/history.js';

const KEY = 'goazen:v1';
const VERSION = 1;

export function today() {
  const d = new Date();
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
}

export const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);

function initialState() {
  return {
    version: VERSION,
    createdAt: new Date().toISOString(),
    settings: {
      restCompound: 150,
      restIsolation: 90,
      stepsGoal: 10000,
      cardioSessionsGoal: 4,
      cardioMinutesGoal: 20,
    },
    customExercises: [],
    exerciseOverrides: {}, // { id: { inc } }
    blocks: [structuredClone(BLOCK_1_2), structuredClone(BLOCK_3)],
    activeBlockId: BLOCK_3.id,
    sessions: structuredClone(HISTORY),
    activeSessionId: null,
    bodyweight: [],
    steps: [], // { date, steps, cardioMin }
  };
}

let state = load();
const listeners = new Set();

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return migrate(JSON.parse(raw));
  } catch (e) {
    console.warn('No se pudo leer el almacenamiento', e);
  }
  return initialState();
}

function migrate(s) {
  const base = initialState();
  const out = { ...base, ...s, settings: { ...base.settings, ...s.settings } };
  if (out.settings.cardioSessionsGoal === 2) out.settings.cardioSessionsGoal = 4; // objetivo actualizado
  // El Bloque 3 se retrasó al 5 de octubre (semana del 28 sep de recuperación).
  const b3 = out.blocks.find((b) => b.id === 'bloque3');
  if (b3?.startDate === '2026-09-21' && !out.sessions.some((x) => x.blockId === 'bloque3')) b3.startDate = '2026-10-05';
  return out;
}

export function get() {
  return state;
}

export function update(fn) {
  fn(state);
  save();
  for (const l of listeners) l(state);
}

export function subscribe(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

let saveError = null;
function save() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
    saveError = null;
  } catch (e) {
    saveError = e;
    console.error('No se pudo guardar', e);
  }
}
export const lastSaveError = () => saveError;

export function replaceAll(next) {
  state = migrate(next);
  save();
  for (const l of listeners) l(state);
}

export function resetAll() {
  state = initialState();
  save();
  for (const l of listeners) l(state);
}

// Pide al navegador que no borre los datos si falta espacio.
export async function requestPersistence() {
  try {
    if (navigator.storage?.persist && !(await navigator.storage.persisted())) {
      return await navigator.storage.persist();
    }
    return true;
  } catch {
    return false;
  }
}

// ── Consultas ───────────────────────────────────────────────────────────────

export function exercises() {
  const all = [...EXERCISES, ...state.customExercises];
  return Object.fromEntries(
    all.map((e) => [e.id, { ...e, ...(state.exerciseOverrides[e.id] ?? {}) }]),
  );
}

export function activeBlock() {
  return state.blocks.find((b) => b.id === state.activeBlockId) ?? state.blocks[state.blocks.length - 1];
}

export function blockById(id) {
  return state.blocks.find((b) => b.id === id);
}

export function sessionById(id) {
  return state.sessions.find((s) => s.id === id);
}

export function finishedSessions() {
  return state.sessions.filter((s) => s.finished);
}

// Siguiente (semana, día) del bloque sin sesión terminada.
export function nextSlot(block = activeBlock()) {
  const done = new Set(
    state.sessions.filter((s) => s.finished && s.blockId === block.id).map((s) => `${s.week}|${s.dayId}`),
  );
  for (const w of block.weeks) for (const d of block.days) if (!done.has(`${w}|${d.id}`)) return { week: w, dayId: d.id };
  return null;
}

export function sessionFor(blockId, week, dayId) {
  return state.sessions.find((s) => s.blockId === blockId && s.week === week && s.dayId === dayId);
}
