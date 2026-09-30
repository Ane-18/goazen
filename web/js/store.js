// Estado de la app guardado en el propio móvil (localStorage). Nada sale del dispositivo.
import { EXERCISES } from './data/exercises.js';
import { BLOCK_1_2, BLOCK_3 } from './data/blocks.js';
import { HISTORY } from './data/history.js';
import { PLAN_BLOQUE1 } from './data/plan-bloque1.js';

const KEY = 'goazen:v1';
const VERSION = 1;

export function today() {
  const d = new Date();
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
}

export const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);

// Perfiles: cada móvil guarda uno.
// ane: su historial de las semanas 1–8 y el Bloque 3 · nuevo: empieza de cero con el Bloque 1 (plan en máquinas).
export const PROFILES = {
  ane: {
    name: 'Ane',
    settings: { stepsGoal: 10000, cardioSessionsGoal: 4, cardioMinutesGoal: 20 },
    blocks: () => [structuredClone(BLOCK_1_2), structuredClone(BLOCK_3)],
    activeBlockId: BLOCK_3.id,
    sessions: () => structuredClone(HISTORY),
  },
  nuevo: {
    name: '',
    settings: { stepsGoal: 8000, cardioSessionsGoal: 4, cardioMinutesGoal: 25 },
    blocks: () => [structuredClone(PLAN_BLOQUE1)],
    activeBlockId: PLAN_BLOQUE1.id,
    sessions: () => [],
  },
};

export function initialState(kind = 'ane', name = PROFILES[kind].name) {
  const p = PROFILES[kind];
  return {
    version: VERSION,
    createdAt: new Date().toISOString(),
    profile: { kind, name },
    settings: {
      restCompound: 150,
      restIsolation: 90,
      ...p.settings,
    },
    customExercises: [],
    exerciseOverrides: {}, // { id: { inc } }
    blocks: p.blocks(),
    activeBlockId: p.activeBlockId,
    sessions: p.sessions(),
    activeSessionId: null,
    bodyweight: [],
    steps: [], // { date, steps, cardioMin }
  };
}

// null = móvil sin datos: la app pregunta quién la va a usar (ver views/welcome.js).
let state = load();
const listeners = new Set();

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return migrate(JSON.parse(raw));
  } catch (e) {
    console.warn('No se pudo leer el almacenamiento', e);
  }
  return null;
}

export function migrate(s) {
  // Los datos guardados antes de que existieran los perfiles son de Ane.
  const profile = s.profile ?? { kind: 'ane', name: 'Ane' };
  const base = initialState(PROFILES[profile.kind] ? profile.kind : 'ane', profile.name);
  const out = { ...base, ...s, profile, settings: { ...base.settings, ...s.settings } };
  if (out.settings.cardioSessionsGoal === 2) out.settings.cardioSessionsGoal = 4; // objetivo actualizado
  // Bloque 3 actualizado (nuevo orden de días, fecha de inicio…): se sustituye mientras no se haya empezado.
  const i3 = out.blocks.findIndex((b) => b.id === BLOCK_3.id);
  if (i3 !== -1 && (out.blocks[i3].rev ?? 1) < BLOCK_3.rev && !out.sessions.some((x) => x.blockId === BLOCK_3.id)) {
    out.blocks[i3] = structuredClone(BLOCK_3);
  }
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

// Primer uso en este móvil: crea el perfil elegido.
export function createProfile(kind, name) {
  state = initialState(kind, name);
  save();
  for (const l of listeners) l(state);
}

export const needsProfile = () => state === null;
export const profile = () => state?.profile ?? { kind: 'ane', name: 'Ane' };

// Vuelve al estado inicial del mismo perfil.
export function resetAll() {
  state = initialState(profile().kind, profile().name);
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
