// Bloques de entrenamiento iniciales, transcritos de los Excel de Ane.
// reps: rango por semana del bloque { semana: [min, max] }.
// sets: [min, max] series de trabajo.

const STRENGTH_THEN_HYPERTROPHY = { 9: [6, 8], 10: [6, 8], 11: [10, 12], 12: [10, 12] };
const fixed = (lo, hi) => ({ 9: [lo, hi], 10: [lo, hi], 11: [lo, hi], 12: [lo, hi] });

const item = (exerciseId, sets, reps, note = '', extra = {}) => ({
  exerciseId,
  sets,
  reps,
  note,
  optional: extra.optional ?? false,
});

export const BLOCK_3 = {
  id: 'bloque3',
  name: 'Bloque 3',
  weeks: [9, 10, 11, 12],
  startDate: '2026-10-05', // semana del 28 sep: recuperación, sin registrar
  rir: [1, 2],
  description:
    'Semanas 9–10: rango de fuerza (6–8 reps, más peso). Semanas 11–12: rango de hipertrofia (10–12 reps). Accesorios en 12–15+.',
  days: [
    {
      id: 'd1',
      name: 'Día 1',
      subtitle: 'Pecho, hombro, espalda, tríceps y abdomen',
      items: [
        item('press_mancuernas', [3, 4], STRENGTH_THEN_HYPERTROPHY, 'Revisa la técnica antes de subir peso: llevas 8 semanas notando hombro y no pecho.'),
        item('remo_barra', [3, 4], STRENGTH_THEN_HYPERTROPHY),
        item('press_militar_mancuernas', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('jalon_supino', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('elev_lateral_polea', [3, 3], fixed(12, 15)),
        item('ext_triceps_polea', [2, 3], fixed(12, 15), 'Vuelve en lugar del press francés.'),
        item('crunch_maquina', [3, 3], fixed(12, 15), 'Nuevo, como pediste.'),
      ],
    },
    {
      id: 'd2',
      name: 'Día 2',
      subtitle: 'Pierna y glúteo (énfasis glúteo)',
      items: [
        item('hip_thrust', [4, 4], STRENGTH_THEN_HYPERTROPHY),
        item('prensa_pies_altos', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('rdl', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('hack', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('curl_femoral', [3, 3], fixed(12, 15)),
        item('puente_banda', [3, 3], fixed(15, 20)),
      ],
    },
    {
      id: 'd3',
      name: 'Día 3',
      subtitle: 'Torso (variante de ángulos y agarres)',
      items: [
        item('press_inclinado_mancuernas', [3, 4], STRENGTH_THEN_HYPERTROPHY),
        item('remo_mancuerna', [3, 4], STRENGTH_THEN_HYPERTROPHY),
        item('face_pull', [3, 3], fixed(12, 15)),
        item('jalon_prono', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('curl_martillo', [3, 3], fixed(10, 12)),
        item('ext_triceps_cuerda', [2, 3], fixed(12, 15), 'Sustituye a los fondos en máquina.'),
        item('abs_elevacion_piernas', [3, 3], fixed(12, 15), 'Opcional si el tiempo aprieta.', { optional: true }),
      ],
    },
    {
      id: 'd4',
      name: 'Día 4',
      subtitle: 'Pierna y glúteo (variante)',
      items: [
        item('zancadas', [3, 3], STRENGTH_THEN_HYPERTROPHY, 'Reps por pierna.'),
        item('peso_muerto', [3, 4], STRENGTH_THEN_HYPERTROPHY),
        item('goblet', [3, 3], STRENGTH_THEN_HYPERTROPHY),
        item('patada_polea', [3, 3], fixed(12, 15)),
        item('curl_femoral', [3, 3], fixed(12, 15)),
        item('abs_rueda_plancha', [3, 3], fixed(10, 15), 'Opcional. En plancha, anota segundos en "reps".', { optional: true }),
      ],
    },
  ],
  changes: [
    { week: 9, from: 'press_frances', to: 'ext_triceps_polea', reason: 'No te gustaba y no notabas progreso. La extensión en polea progresaba bien (llegaste a 27 kg).' },
    { week: 9, from: 'fondos_maquina', to: 'ext_triceps_cuerda', reason: '4 semanas estancada en 32 kg y no te gustaba.' },
    { week: 9, from: null, to: 'crunch_maquina', reason: 'Lo pediste tras 8 semanas casi sin abdominales.' },
  ],
};

// Semanas 1–8 (bloques 1 y 2). Sirve de referencia histórica: los datos están en history.js.
export const BLOCK_1_2 = {
  id: 'bloque1_2',
  name: 'Bloques 1–2',
  weeks: [1, 2, 3, 4, 5, 6, 7, 8],
  startDate: '2026-07-13',
  rir: [1, 3],
  archived: true,
  description: 'Importado del Excel. Las fechas son aproximadas (el Excel solo registra la semana).',
  days: [
    { id: 'd1', name: 'Día 1', subtitle: 'Pecho, hombro, espalda, tríceps y abdomen', items: [] },
    { id: 'd2', name: 'Día 2', subtitle: 'Pierna y glúteo (énfasis glúteo)', items: [] },
    { id: 'd3', name: 'Día 3', subtitle: 'Torso (variante de ángulos y agarres)', items: [] },
    { id: 'd4', name: 'Día 4', subtitle: 'Pierna y glúteo (variante)', items: [] },
  ],
  changes: [
    { week: 5, from: 'elev_lateral_mancuernas', to: 'elev_lateral_polea', reason: 'Estancada 3 semanas en 4 kg. La polea permite subir de 1 en 1 kg.' },
    { week: 5, from: 'ext_triceps_polea', to: 'press_frances', reason: 'Cambio de variante.' },
    { week: 5, from: 'bulgara', to: 'prensa_pies_altos', reason: 'Molestias y náuseas con la búlgara.' },
    { week: 5, from: 'ext_cuadriceps', to: 'hack', reason: 'Cambio a un compuesto guiado.' },
    { week: 5, from: 'press_inclinado_barra', to: 'press_inclinado_mancuernas', reason: 'Dolor lumbar y pérdida de sensación del músculo con barra.' },
    { week: 5, from: 'elev_frontal_pajaros', to: 'face_pull', reason: 'Estancada en 4 kg.' },
    { week: 5, from: 'curl_biceps', to: 'curl_martillo', reason: 'Cambio de variante.' },
    { week: 5, from: null, to: 'curl_femoral', reason: 'Recuperado: el puente a una pierna tiraba de la lumbar y no se sentía el músculo.' },
    { week: 6, from: 'abductores', to: 'puente_banda', reason: 'El puente con banda se siente mejor y no depende de que la máquina esté libre.' },
  ],
};
