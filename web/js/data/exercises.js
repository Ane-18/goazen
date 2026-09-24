// Catálogo de ejercicios.
// muscles.p = músculos principales (cuentan 1 serie), muscles.s = secundarios (cuentan 0,5).
// Conteo fraccional como en Pelland et al. 2024 (metarregresión dosis-respuesta de volumen).
// equip: mancuerna | barra | maquina | polea | banda | corporal
// inc: incremento de carga por defecto (kg). En mancuernas es por mancuerna.

export const MUSCLES = {
  pecho: 'Pecho',
  espalda: 'Espalda',
  hombro_ant: 'Hombro anterior',
  hombro_lat: 'Hombro lateral',
  hombro_post: 'Hombro posterior',
  biceps: 'Bíceps',
  triceps: 'Tríceps',
  cuadriceps: 'Cuádriceps',
  gluteo: 'Glúteo',
  isquios: 'Isquiotibiales',
  abdomen: 'Abdomen',
};

const ex = (id, name, equip, p, s = [], extra = {}) => ({
  id,
  name,
  equip,
  muscles: { p, s },
  inc: extra.inc ?? defaultInc(equip),
  compound: extra.compound ?? false,
  cue: extra.cue ?? '',
  unilateral: extra.unilateral ?? false,
});

function defaultInc(equip) {
  return { mancuerna: 1, barra: 2.5, maquina: 2.5, polea: 2.5, banda: 0, corporal: 0 }[equip] ?? 2.5;
}

export const EXERCISES = [
  // ── Torso: empuje ─────────────────────────────────────────────
  ex('press_mancuernas', 'Press banca o inclinado con mancuernas', 'mancuerna', ['pecho'], ['triceps', 'hombro_ant'], {
    compound: true, inc: 2,
    cue: 'Escápulas retraídas contra el banco, codos a 45–60° (no en cruz), baja hasta notar estiramiento del pecho.',
  }),
  ex('press_inclinado_mancuernas', 'Press inclinado con mancuernas', 'mancuerna', ['pecho'], ['hombro_ant', 'triceps'], {
    compound: true, inc: 2,
    cue: 'Banco a 30–45°. Mismo agarre y técnica que el press del Día 1.',
  }),
  ex('press_inclinado_barra', 'Press inclinado con barra o máquina', 'barra', ['pecho'], ['hombro_ant', 'triceps'], { compound: true }),
  ex('press_maquina_pecho', 'Press de pecho en máquina', 'maquina', ['pecho'], ['triceps', 'hombro_ant'], {
    compound: true, cue: 'Máquina guiada: fácil sentir el pecho sin preocuparte del equilibrio.',
  }),
  ex('aperturas_polea', 'Aperturas en polea (cruce)', 'polea', ['pecho'], [], {
    cue: 'Codos ligeramente flexionados; abre hasta notar estiramiento del pecho.',
  }),
  ex('pec_deck', 'Contractor de pecho (pec deck)', 'maquina', ['pecho'], []),
  ex('press_militar_mancuernas', 'Press militar con mancuernas', 'mancuerna', ['hombro_ant'], ['hombro_lat', 'triceps'], {
    compound: true, cue: 'Agarre neutro si notas el hombro.',
  }),
  ex('press_hombro_maquina', 'Press de hombro en máquina', 'maquina', ['hombro_ant'], ['hombro_lat', 'triceps'], { compound: true }),
  ex('elev_lateral_mancuernas', 'Elevaciones laterales con mancuernas', 'mancuerna', ['hombro_lat'], []),
  ex('elev_lateral_polea', 'Elevación lateral en polea', 'polea', ['hombro_lat'], [], {
    inc: 1, cue: 'Peso ligero y controlado, sin balanceo. La polea permite subir de 1 en 1 kg.',
  }),
  ex('elev_frontal_pajaros', 'Elevación frontal + pájaros', 'mancuerna', ['hombro_post'], ['hombro_ant']),
  ex('ext_triceps_polea', 'Extensión de tríceps en polea', 'polea', ['triceps'], [], {
    cue: 'Agarre cerrado, codos pegados al cuerpo.',
  }),
  ex('ext_triceps_cuerda', 'Extensión de tríceps en polea con cuerda', 'polea', ['triceps'], [], {
    cue: 'Separa las manos al final del recorrido.',
  }),
  ex('ext_triceps_overhead', 'Extensión de tríceps por encima de la cabeza en polea', 'polea', ['triceps'], [], {
    cue: 'Posición de estiramiento del tríceps; útil como variante.',
  }),
  ex('press_frances', 'Press francés con mancuerna', 'mancuerna', ['triceps'], []),
  ex('fondos_maquina', 'Fondos en máquina o press cerrado', 'maquina', ['triceps'], ['pecho'], { compound: true }),

  // ── Torso: tirón ──────────────────────────────────────────────
  ex('remo_barra', 'Remo con barra o máquina', 'barra', ['espalda'], ['biceps', 'hombro_post'], {
    compound: true, cue: 'Agarre prono ancho → más espalda.',
  }),
  ex('remo_mancuerna', 'Remo con mancuerna a un brazo', 'mancuerna', ['espalda'], ['biceps', 'hombro_post'], {
    compound: true, inc: 2, cue: 'Agarre neutro.',
  }),
  ex('remo_polea_baja', 'Remo en polea baja', 'polea', ['espalda'], ['biceps', 'hombro_post'], { compound: true }),
  ex('remo_pecho_apoyado', 'Remo con pecho apoyado en máquina', 'maquina', ['espalda'], ['biceps', 'hombro_post'], {
    compound: true, cue: 'El pecho apoyado quita carga a la zona lumbar.',
  }),
  ex('jalon_supino', 'Jalón al pecho (agarre supino estrecho)', 'polea', ['espalda'], ['biceps'], {
    compound: true, cue: 'Agarre supino estrecho → más bíceps.',
  }),
  ex('jalon_prono', 'Jalón al pecho (agarre prono ancho)', 'polea', ['espalda'], ['biceps'], {
    compound: true, cue: 'Agarre prono ancho → espalda más ancha.',
  }),
  ex('dominadas_asistidas', 'Dominadas asistidas en máquina', 'maquina', ['espalda'], ['biceps'], { compound: true }),
  ex('face_pull', 'Face pull en polea', 'polea', ['hombro_post'], ['espalda'], {
    cue: 'Tira hacia la cara con los codos altos.',
  }),
  ex('pajaro_maquina', 'Pájaro en máquina (pec deck invertido)', 'maquina', ['hombro_post'], []),
  ex('curl_biceps', 'Curl de bíceps con mancuernas', 'mancuerna', ['biceps'], []),
  ex('curl_martillo', 'Curl martillo con mancuerna', 'mancuerna', ['biceps'], [], {
    cue: 'Agarre neutro (palmas enfrentadas).',
  }),
  ex('curl_polea', 'Curl de bíceps en polea', 'polea', ['biceps'], []),

  // ── Pierna ───────────────────────────────────────────────────
  ex('hip_thrust', 'Hip thrust', 'barra', ['gluteo'], ['isquios'], {
    compound: true, cue: 'Prioridad glúteo: pausa de 1–2 s arriba.',
  }),
  ex('prensa_pies_altos', 'Prensa de piernas (pies altos y separados)', 'maquina', ['cuadriceps'], ['gluteo'], {
    compound: true, inc: 5, cue: 'Pies altos y separados: más glúteo e isquio.',
  }),
  ex('rdl', 'Peso muerto rumano', 'mancuerna', ['isquios'], ['gluteo'], {
    compound: true, inc: 2, cue: 'Agarre prono. Cadera atrás, espalda neutra, nota el estiramiento del isquio.',
  }),
  ex('hack', 'Sentadilla hack en máquina', 'maquina', ['cuadriceps'], ['gluteo'], {
    compound: true, inc: 5, cue: 'Espalda apoyada, recorrido guiado.',
  }),
  ex('curl_femoral', 'Curl femoral en máquina', 'maquina', ['isquios'], []),
  ex('curl_femoral_sentado', 'Curl femoral sentado', 'maquina', ['isquios'], [], {
    cue: 'Sentado se entrena el isquio más estirado; buena opción para hipertrofia.',
  }),
  ex('puente_banda', 'Puente de glúteo con banda en rodillas', 'banda', ['gluteo'], [], {
    cue: 'Banda por encima de la rodilla, empuja hacia fuera.',
  }),
  ex('zancadas', 'Zancadas o step-up', 'mancuerna', ['cuadriceps', 'gluteo'], [], {
    compound: true, inc: 2, unilateral: true, cue: 'Unilateral: corrige asimetrías y activa glúteo medio y core. Reps por pierna.',
  }),
  ex('peso_muerto', 'Peso muerto convencional o rumano con mancuernas', 'mancuerna', ['gluteo', 'isquios'], ['cuadriceps'], {
    compound: true, inc: 2, cue: 'Agarre prono o mixto si el peso es alto.',
  }),
  ex('goblet', 'Prensa o sentadilla goblet', 'mancuerna', ['cuadriceps'], ['gluteo'], {
    compound: true, inc: 2, cue: 'Énfasis cuádriceps.',
  }),
  ex('patada_polea', 'Patada de glúteo en polea', 'polea', ['gluteo'], []),
  ex('bulgara', 'Sentadilla búlgara', 'mancuerna', ['cuadriceps', 'gluteo'], [], { compound: true, unilateral: true }),
  ex('ext_cuadriceps', 'Extensión de cuádriceps en máquina', 'maquina', ['cuadriceps'], []),
  ex('abductores', 'Abductores en máquina', 'maquina', ['gluteo'], []),
  ex('hip_thrust_maquina', 'Hip thrust en máquina', 'maquina', ['gluteo'], ['isquios'], { compound: true, inc: 5 }),
  ex('sentadilla_smith', 'Sentadilla en multipower (Smith)', 'barra', ['cuadriceps'], ['gluteo'], { compound: true }),

  // ── Abdomen ──────────────────────────────────────────────────
  ex('crunch_maquina', 'Crunch abdominal en máquina', 'maquina', ['abdomen'], []),
  ex('abs_crunch_polea', 'Crunch en polea o plancha', 'polea', ['abdomen'], []),
  ex('abs_elevacion_piernas', 'Elevación de piernas', 'corporal', ['abdomen'], []),
  ex('abs_rueda_plancha', 'Rueda abdominal o plancha lateral', 'corporal', ['abdomen'], []),
];

export const EXERCISE_BY_ID = Object.fromEntries(EXERCISES.map((e) => [e.id, e]));
