// Genera el Excel del Bloque 1 de la madre usando el Excel de Ane como plantilla de estilos.
// Uso: node gen_madre.cjs <carpeta_plantilla_descomprimida> <carpeta_salida>
const fs = require('fs');
const path = require('path');

const [TPL, OUT] = process.argv.slice(2);
fs.rmSync(OUT, { recursive: true, force: true });

// Copia la plantilla sin fotos ni dibujos (las fotos eran de los ejercicios de Ane).
function copy(dir) {
  for (const f of fs.readdirSync(path.join(TPL, dir))) {
    const rel = path.join(dir, f);
    if (/^xl[\\/](media|drawings)/.test(rel) || /^xl[\\/]worksheets[\\/]_rels/.test(rel)) continue;
    const src = path.join(TPL, rel);
    if (fs.statSync(src).isDirectory()) copy(rel);
    else { fs.mkdirSync(path.join(OUT, dir), { recursive: true }); fs.copyFileSync(src, path.join(OUT, rel)); }
  }
}
copy('');

// ── Cadenas compartidas ─────────────────────────────────────────────────────
const sst = [];
const sidx = new Map();
const xml = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
function S(text) {
  if (!sidx.has(text)) { sidx.set(text, sst.length); sst.push(text); }
  return sidx.get(text);
}
const cell = (ref, s, v) => {
  if (v === undefined || v === null || v === '') return `<c r="${ref}" s="${s}"/>`;
  if (typeof v === 'number') return `<c r="${ref}" s="${s}"><v>${v}</v></c>`;
  if (typeof v === 'object' && v.f) return `<c r="${ref}" s="${s}"${v.str ? ' t="str"' : ''}><f>${xml(v.f)}</f></c>`;
  return `<c r="${ref}" s="${s}" t="s"><v>${S(v)}</v></c>`;
};
const COLS = 'ABCDEFGHIJKLMNOPQRS'.split('');
// Alto de fila aproximado para texto que se ajusta: caracteres por línea según ancho de columna.
const rowHeight = (text, charsPerLine, lineHt = 13, pad = 8, min = 15) =>
  Math.max(min, Math.ceil(String(text).length / charsPerLine + String(text).split('\n').length - 1) * lineHt + pad);

const HEAD = fs.readFileSync(path.join(TPL, 'xl/worksheets/sheet2.xml'), 'utf8');
const NS = HEAD.slice(0, HEAD.indexOf('<sheetPr>'));
const TAIL = '<printOptions/><pageMargins bottom="1.0" footer="0.0" header="0.0" left="0.75" right="0.75" top="1.0"/><pageSetup paperSize="9" orientation="portrait"/>';

// ── Plan ────────────────────────────────────────────────────────────────────
const MAIN = 'Sem 1-2: 2 x 12-15 | Sem 3-4: 3 x 10-12';
const ACC = 'Sem 1-2: 2 x 12-15 | Sem 3-4: 3 x 12-15';
const yt = (q) => `https://www.youtube.com/results?search_query=${encodeURIComponent(q)}`;

const ROW = 'Sem 1-2: 2 x 12-15 | Sem 3-4: 3-4 x 10-12';
const DAYS = [
  {
    title: 'DIA 1 - LUNES',
    subtitle: 'Torso (pecho, espalda y brazos) y abdomen',
    items: [
      ['Rotación externa en polea (codo pegado)', 'Sem 1-2: 2 x 12-15 | Sem 3-4: 3 x 12-15', 'Para el hombro, y es el primer ejercicio para ver cómo está el brazo ese día. Polea a la altura del codo, codo pegado al costado y doblado a 90°. Gira el antebrazo hacia fuera y vuelve despacio. Muy ligero: deja siempre 3 o más repeticiones en reserva.', 'rotación externa en polea codo pegado manguito rotador'],
      ['Press de pecho en máquina', MAIN, 'Agarre neutro (palmas enfrentadas) si la máquina lo tiene. Codos a unos 45° del cuerpo, nunca a la altura de los hombros. Si el brazo molesta al final de la bajada, no bajes tanto.', 'press de pecho en máquina técnica'],
      ['Remo sentado en máquina (agarre neutro)', ROW, 'Tu ejercicio de espalda del día. Pecho apoyado en el respaldo. Tira llevando los codos atrás, pegados al cuerpo, y junta las escápulas al final. En las semanas 3-4 puedes hacer una 4ª serie si te ves con fuerza.', 'remo sentado en máquina agarre neutro técnica'],
      ['Extensión de tríceps en polea', ACC, 'Barra corta, codos pegados al cuerpo; solo se mueve el antebrazo. Estira del todo abajo y sube despacio.', 'extensión de tríceps en polea técnica'],
      ['Curl de bíceps con mancuernas', ACC, 'Sentada, con la espalda apoyada. Palmas hacia delante y codos pegados. Con mancuernas puedes ajustar un poco la posición del brazo si notas molestia.', 'curl de bíceps con mancuernas sentado técnica'],
      ['Crunch abdominal en máquina', ACC, 'Enrolla el tronco acercando las costillas a la cadera. No tires con los brazos.', 'crunch abdominal en máquina técnica'],
    ],
  },
  {
    title: 'DIA 2 - MARTES',
    subtitle: 'Pierna y glúteo',
    items: [
      ['Prensa de piernas', MAIN, 'Pies en el centro de la plataforma, a la anchura de la cadera. Baja hasta que las rodillas formen unos 90° sin que se despegue la zona lumbar del respaldo. Empuja con todo el pie.', 'prensa de piernas técnica correcta'],
      ['Hip thrust en máquina', MAIN, 'Empuja con los talones y aprieta el glúteo 1 segundo arriba. Termina con la cadera alineada, sin arquear la zona lumbar.', 'hip thrust en máquina técnica'],
      ['Curl femoral sentado', ACC, 'Rodilla alineada con el eje de la máquina. Baja los talones con fuerza y vuelve despacio (2-3 segundos).', 'curl femoral sentado técnica'],
      ['Extensión de cuádriceps en máquina', ACC, 'Estira del todo, aprieta 1 segundo y baja despacio. Si molesta la rodilla, acorta el recorrido de abajo.', 'extensión de cuádriceps en máquina técnica'],
      ['Abductores en máquina', ACC, 'Torso un poco inclinado hacia delante para que trabaje más el glúteo. Abre y cierra controlando, sin rebotes.', 'abductores en máquina glúteo medio'],
      ['Elevación de talones en prensa (gemelo)', ACC, 'Solo la punta del pie en el borde de la plataforma, rodillas casi estiradas. Sube de puntillas, pausa arriba y baja hasta notar el estiramiento.', 'elevación de talones en prensa gemelo'],
    ],
  },
  {
    title: 'DIA 3 - JUEVES',
    subtitle: 'Torso (variante) y abdomen',
    items: [
      ['Rotación externa en polea (codo pegado)', 'Sem 1-2: 2 x 12-15 | Sem 3-4: 3 x 12-15', 'La misma que el lunes. Polea a la altura del codo, codo pegado al costado y doblado a 90°. Gira el antebrazo hacia fuera y vuelve despacio. Muy ligero: deja siempre 3 o más repeticiones en reserva.', 'rotación externa en polea codo pegado manguito rotador'],
      ['Press de pecho en máquina', MAIN, 'El mismo que el lunes: repetirlo dos veces por semana hace que aprendas la técnica antes y progreses más. Codos a 45°, nunca a la altura de los hombros.', 'press de pecho en máquina técnica'],
      ['Remo unilateral en máquina (pecho apoyado)', ROW, 'Tu ejercicio de espalda del día. Un brazo cada vez, con el pecho apoyado: empieza por el brazo más débil y haz las mismas repeticiones con el otro. En las semanas 3-4 puedes hacer una 4ª serie.', 'remo unilateral en máquina pecho apoyado'],
      ['Extensión de tríceps en polea', ACC, 'La misma que el lunes: barra corta, codos pegados al cuerpo; solo se mueve el antebrazo. Hacerla dos veces por semana te hace progresar más en ella.', 'extensión de tríceps en polea técnica'],
      ['Curl martillo con mancuerna', ACC, 'Sentada o de pie, palmas enfrentadas y codos pegados. Con mancuernas puedes ajustar un poco la posición si notas el brazo.', 'curl martillo con mancuernas técnica'],
      ['Elevación de piernas', ACC, 'Tumbada boca arriba, rodillas dobladas y brazos en el suelo junto al cuerpo. Sube las rodillas hacia el pecho y baja despacio sin que la zona lumbar se despegue del suelo. Nunca colgada de una barra.', 'elevación de piernas tumbada rodillas dobladas abdominales'],
    ],
  },
  {
    title: 'DIA 4 - VIERNES',
    subtitle: 'Pierna y glúteo (variante)',
    items: [
      ['Prensa de piernas (pies altos y separados)', MAIN, 'Pies en la parte alta de la plataforma y algo más abiertos que la cadera: así trabaja más el glúteo y la parte de atrás del muslo.', 'prensa de piernas pies altos glúteo'],
      ['Hiperextensiones a 45°', ACC, 'Sin peso al principio y brazos cruzados en el pecho. Baja doblando la cadera con la espalda recta y sube apretando el glúteo hasta quedar en línea, sin pasarte hacia atrás.', 'hiperextensiones 45 grados glúteo técnica'],
      ['Zancadas caminando con mancuernas', 'Sem 1-2: 2 x 8-10 | Sem 3-4: 3 x 8-10 (pasos por pierna)', 'Semanas 1-2 sin peso, para aprender el equilibrio; semanas 3-4 con mancuernas ligeras colgando a los lados. Paso largo, torso recto y rodilla de delante hacia la punta del pie. Si las mancuernas tiran del brazo, hazlas sin peso.', 'zancadas caminando con mancuernas técnica'],
      ['Curl femoral en máquina', ACC, 'Tumbada o sentada, según la máquina que haya libre. Vuelve despacio, sin dejar caer el peso.', 'curl femoral en máquina técnica'],
      ['Patada de glúteo en polea', ACC, 'Tobillera en la polea baja, de cara a la máquina y sujetándote a ella con las manos a la altura de la cintura. Torso quieto; lleva la pierna atrás apretando el glúteo, sin arquear la zona lumbar.', 'patada de glúteo en polea técnica'],
      ['Aductores en máquina', ACC, 'Cierra las piernas controlando y abre despacio hasta donde estés cómoda, sin forzar la apertura.', 'aductores en máquina técnica'],
    ],
  },
];

const NOTE = "La columna gris es la semana de prueba (del 26 de octubre al 1 de noviembre): esa semana no se apunta nada, solo pruebas pesos y ves si algún ejercicio molesta. Desde el lunes 2 de noviembre rellena Peso, Reps y RIR de cada semana. Si en todas las series llegas al máximo de repeticiones con buena técnica -> sube el peso la semana siguiente (torso: +1-2,5 kg / pierna: +2,5-5 kg). Si no, repite el mismo peso e intenta hacer 1 repetición más. Semanas 1-2: 2 series dejando 3 repeticiones en reserva (RIR 3). Semanas 3-4: 3 series (el remo, 3-4) dejando 2 (RIR 2). Si el brazo molesta más de 3 sobre 10, para ese ejercicio.";

// ── Hojas de día ────────────────────────────────────────────────────────────
function daySheet(day) {
  const rows = [];
  const links = [];
  const fill = (r, from, s) => COLS.slice(COLS.indexOf(from)).map((c) => cell(`${c}${r}`, s)).join('');
  rows.push(`<row r="1" ht="24.0" customHeight="1">${cell('A1', 17, day.title)}${COLS.slice(1, 18).map((c) => cell(c + 1, 10)).join('')}${cell('S1', 11)}</row>`);
  rows.push(`<row r="2" ht="18.0" customHeight="1">${cell('A2', 9, day.subtitle)}${COLS.slice(1, 18).map((c) => cell(c + 2, 10)).join('')}${cell('S2', 11)}</row>`);
  const wk = (c1, s, n) => cell(c1, s, `SEMANA ${n}`);
  rows.push(`<row r="3" ht="18.0" customHeight="1">${cell('A3', 18, 'Ejercicio')}${cell('B3', 18, 'Vídeo')}${cell('C3', 18, 'Series x Reps')}${cell('D3', 18, 'Agarre / nota')}${cell('E3', 19, 'PRUEBA (26 oct-1 nov)')}${cell('F3', 14)}${cell('G3', 15)}${wk('H3', 20, 1)}${cell('I3', 14)}${cell('J3', 15)}${wk('K3', 21, 2)}${cell('L3', 14)}${cell('M3', 15)}${wk('N3', 20, 3)}${cell('O3', 14)}${cell('P3', 15)}${wk('Q3', 21, 4)}${cell('R3', 14)}${cell('S3', 15)}</row>`);
  const sub = (c, s, t) => cell(c + 4, s, t);
  rows.push(`<row r="4" ht="15.75" customHeight="1">${['A', 'B', 'C', 'D'].map((c) => cell(c + 4, 22)).join('')}${sub('E', 23, 'Peso')}${sub('F', 23, 'Reps')}${sub('G', 23, 'RIR')}${[['H', 24], ['K', 25], ['N', 24], ['Q', 25]].map(([c, s]) => { const i = COLS.indexOf(c); return sub(COLS[i], s, 'Peso (kg)') + sub(COLS[i + 1], s, 'Reps') + sub(COLS[i + 2], s, 'RIR'); }).join('')}</row>`);

  day.items.forEach(([name, sr, note, q], k) => {
    const r = 5 + k;
    const odd = k % 2 === 0;
    const [sA, sB, sC, sW] = odd ? [26, 28, 28, 30] : [35, 33, 33, 34]; // B centrado como C
    const ht = Math.max(61.5, rowHeight(note, 35));
    links.push({ ref: `B${r}`, url: yt(q) });
    rows.push(`<row r="${r}" ht="${ht}" customHeight="1">${cell(`A${r}`, sA, name)}${cell(`B${r}`, sB, '▶ Ver vídeo')}${cell(`C${r}`, sC, sr)}${cell(`D${r}`, sA, note)}${cell(`E${r}`, 29)}${cell(`F${r}`, 29)}${cell(`G${r}`, 29)}${fill(r, 'H', sW)}</row>`);
  });
  const nr = 5 + day.items.length + 1;
  rows.push(`<row r="${nr}" ht="${rowHeight(NOTE, 150, 12, 6, 30)}" customHeight="1">${cell(`A${nr}`, 36, NOTE)}</row>`);

  const merges = ['H3:J3', 'K3:M3', 'N3:P3', 'Q3:S3', 'A1:S1', 'A2:S2', 'A3:A4', 'B3:B4', 'C3:C4', 'D3:D4', 'E3:G3', `A${nr}:S${nr}`];
  const cols = HEAD.match(/<cols>.*?<\/cols>/)[0];
  const body = `${NS}<sheetPr><pageSetUpPr/></sheetPr><sheetViews><sheetView showGridLines="0" workbookViewId="0"><pane ySplit="4.0" topLeftCell="A5" activePane="bottomLeft" state="frozen"/><selection activeCell="H5" sqref="H5" pane="bottomLeft"/></sheetView></sheetViews><sheetFormatPr customHeight="1" defaultColWidth="14.43" defaultRowHeight="15.0"/>${cols}<sheetData>${rows.join('')}</sheetData><mergeCells count="${merges.length}">${merges.map((m) => `<mergeCell ref="${m}"/>`).join('')}</mergeCells><hyperlinks>${links.map((l, i) => `<hyperlink ref="${l.ref}" r:id="rIdL${i + 1}"/>`).join('')}</hyperlinks>${TAIL}</worksheet>`;
  const rels = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${links.map((l, i) => `<Relationship Id="rIdL${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="${xml(l.url)}" TargetMode="External"/>`).join('')}</Relationships>`;
  return { body, rels };
}

// ── Guía ────────────────────────────────────────────────────────────────────
const GUIDE = [
  ['Por qué pesas y no solo cardio', 'En la transición a la menopausia baja el estrógeno y el cuerpo cambia: se pierde músculo y hueso más deprisa y la grasa tiende a acumularse en la tripa (estudio SWAN). El entrenamiento de fuerza es lo que mejor frena eso: mantiene y aumenta el músculo, fortalece el hueso y mejora cómo el cuerpo gestiona el azúcar. "Tonificar" es justo eso: algo más de músculo y menos grasa encima. Con este plan no te vas a poner "grande"; vas a estar más firme, más fuerte y con más energía.'],
  ['Tu brazo: qué se ha evitado y por qué', 'Con la calcificación, levantar el brazo por encima de la cabeza o hacia el lado suele molestar. Por eso no hay press de hombro, jalón al pecho, elevaciones laterales, aperturas ni ejercicios de abdomen en los que haya que aguantar peso con los brazos estirados. Todos los empujes y tirones son con los brazos por debajo de los hombros y los codos cerca del cuerpo. Regla del dolor: una molestia de hasta 3 sobre 10 durante el ejercicio es aceptable si al día siguiente no está peor. Si pasa de 3, o al día siguiente está peor, baja el peso, acorta el recorrido o quita ese ejercicio ese día. Enséñale este plan a tu médico o fisio: si te dan el visto bueno para algún ejercicio de hombro, se añade en el siguiente bloque. Cada día de torso empieza con rotación externa en polea: fortalecer los músculos que rodean el hombro (el manguito rotador) es lo que más se recomienda para los problemas de tendón del hombro, y se hace con el brazo pegado al cuerpo. Además, al ser el primer ejercicio, te dice cómo está el brazo ese día antes de empezar con el resto.'],
  ['Por qué casi todo en máquina', 'Las máquinas marcan el recorrido, así que se aprenden rápido, es difícil hacerse daño y es muy fácil subir de peso poco a poco (una placa cada vez). Los estudios no encuentran diferencias en fuerza ni en músculo entre máquinas y peso libre, así que no pierdes nada. Las excepciones tienen un motivo. Los curls van con mancuernas porque así puedes ajustar un poco la posición del brazo si notas molestia, cosa que la polea no permite. Las zancadas caminando mejoran el equilibrio y la fuerza de cada pierna por separado, algo muy útil en el día a día (escaleras, cuestas). Las hiperextensiones enseñan a moverse desde la cadera y cuidan la espalda.'],
  ['Semanas 1-2: aprender. Semanas 3-4: apretar un poco más', 'Después de la semana de prueba: semanas 1 y 2, 2 series de 12-15 repeticiones, dejando unas 3 en reserva (RIR 3). Semanas 3 y 4: 3 series; en los ejercicios principales de 10-12 repeticiones, dejando unas 2 en reserva (RIR 2). RIR significa "repeticiones en reserva": las que podrías haber hecho de más con buena técnica. Se empieza suave porque los tendones y las articulaciones se adaptan más despacio que el músculo, y al empezar se progresa muy bien con poco volumen. Así evitas agujetas fuertes y lesiones, y llegas con ganas a la semana siguiente.'],
  ['Semana de prueba: del 26 de octubre al 1 de noviembre', 'La primera semana haces los 4 días completos, pero sin apuntar nada: sirve para aprender las máquinas, encontrar tu peso y ver si algún ejercicio molesta el brazo. En cada ejercicio haz una serie de calentamiento muy ligera y luego 2 series de 12-15 repeticiones. Busca un peso con el que las últimas repeticiones cuesten, pero con la técnica perfecta y dejando unas 3 en reserva. Si te sobran más, sube una placa en la siguiente serie; si no llegas a 12, baja una. Si un ejercicio molesta más de 3 sobre 10, déjalo y coméntalo. El lunes 2 de noviembre empiezas la semana 1 con el peso que hayas encontrado, y desde ahí ya apuntas todo.'],
  ['Cuándo subir de peso', 'Cuando en todas las series llegues al máximo de repeticiones con buena técnica, la semana siguiente sube lo mínimo que permita la máquina (torso: 1-2,5 kg; pierna: 2,5-5 kg). Si no llegas, repite el peso e intenta hacer una repetición más. Así, semana a semana, el músculo recibe un poco más de trabajo: eso es lo que lo hace crecer y lo que te hace notar cambios.'],
  ['Cinta: 20-30 minutos al terminar', 'Camina a paso rápido con algo de inclinación (5-10 %), a un ritmo que te permita hablar pero no cantar. Hacer el cardio después de las pesas no quita resultados. Con 4 días sumas unos 100 minutos a la semana. La OMS recomienda 150-300 minutos de actividad moderada, así que el resto sale de moverte en el día a día: el objetivo son unos 8.000 pasos diarios.'],
  ['Perder grasa: la comida manda', 'El entrenamiento hace que lo que pierdas sea grasa y no músculo, pero para perder grasa hace falta comer algo menos de lo que gastas. Sin dietas extremas, que hacen perder músculo. Lo más importante es la proteína: unos 1,2-1,6 g por kilo de peso al día, repartidos en 3-4 comidas (carne, pescado, huevos, lácteos, legumbres). Dormir bien también cuenta. Para ver el progreso, mejor medirte la cintura cada 2 semanas que mirar solo la báscula.'],
  ['La regla irregular', 'No hace falta planificar el entrenamiento según el ciclo: los estudios no encuentran diferencias importantes en fuerza ni en resultados entre fases. Si un día estás más cansada, con sofocos o has dormido mal, haz una serie menos por ejercicio o deja una repetición más en reserva. Entrenar fuerza ayuda precisamente con el sueño, el ánimo y la energía en esta etapa.'],
  ['Qué vas a notar y cuándo', 'Energía y sueño: en 2-4 semanas. Fuerza: casi cada semana los primeros meses, sobre todo al principio porque el cuerpo aprende los movimientos. Cambios que se ven (cintura, piernas, brazos más firmes): a partir de 8-12 semanas si eres constante y cuidas la comida. Lo que más influye es no fallar: 4 días casi todas las semanas vale más que un entrenamiento perfecto.'],
  ['Base científica', 'Greendale et al. 2019 (estudio SWAN, cambios de composición corporal en la menopausia) · Watson et al. 2018 (LIFTMOR: fuerza y densidad ósea en mujeres posmenopáusicas) · Schoenfeld et al. 2017 (series semanales y crecimiento muscular) · Schumann et al. 2022 (cardio y fuerza juntos no se estorban) · Bull et al. 2020 (guías de actividad física de la OMS) · Paluch et al. 2022 (pasos diarios y salud) · Morton et al. 2018 (proteína y entrenamiento de fuerza) · McNulty et al. 2020 (ciclo menstrual y rendimiento) · Silbernagel et al. 2007 (regla del dolor en tendinopatías).'],
];

function guideSheet() {
  const t = fs.readFileSync(path.join(TPL, 'xl/worksheets/sheet1.xml'), 'utf8');
  const head = t.slice(0, t.indexOf('<sheetData>'));
  const rows = [
    `<row r="1" ht="13.5" customHeight="1">${cell('B1', 1, 'TU GUÍA DE GIMNASIO - BLOQUE 1 (semanas 1-4)')}${cell('C1', 2)}${cell('D1', 2)}${cell('E1', 2)}${cell('F1', 2)}${cell('G1', 3)}</row>`,
    `<row r="2" ht="25.5" customHeight="1">${cell('B2', 4)}${cell('G2', 5)}</row>`,
    `<row r="3" ht="13.5" customHeight="1">${cell('B3', 6)}${cell('C3', 7)}${cell('D3', 7)}${cell('E3', 7)}${cell('F3', 7)}${cell('G3', 8)}</row>`,
    `<row r="4" ht="48.0" customHeight="1">${cell('B4', 9, 'Del 26 de octubre al 1 de noviembre, semana de prueba: entrenas sin apuntar nada. Desde el lunes 2 de noviembre, semanas 1-4, apuntando cada entreno. Lunes y jueves torso, martes y viernes pierna y glúteo, con 20-30 minutos de cinta al terminar. Miércoles, sábado y domingo, descanso (caminar sí cuenta). Objetivo: más energía, menos grasa y un cuerpo más firme y fuerte.')}${cell('C4', 10)}${cell('D4', 10)}${cell('E4', 10)}${cell('F4', 10)}${cell('G4', 11)}</row>`,
    `<row r="6">${cell('B6', 12, 'CÓMO FUNCIONA ESTE PLAN')}</row>`,
  ];
  const merges = ['B1:G3', 'B4:G4', 'B6:E6'];
  let r = 8;
  for (const [title, text] of GUIDE) {
    rows.push(`<row r="${r}" ht="18.0" customHeight="1">${cell(`B${r}`, 13, `  ${title}`)}${cell(`C${r}`, 14)}${cell(`D${r}`, 14)}${cell(`E${r}`, 15)}</row>`);
    rows.push(`<row r="${r + 1}" ht="${rowHeight(text, 88, 13, 10)}" customHeight="1">${cell(`B${r + 1}`, 16, `  ${text}`)}</row>`);
    merges.push(`B${r}:E${r}`, `B${r + 1}:E${r + 1}`);
    r += 3;
  }
  return `${head}<sheetData>${rows.join('')}</sheetData><mergeCells count="${merges.length}">${merges.map((m) => `<mergeCell ref="${m}"/>`).join('')}</mergeCells>${TAIL}</worksheet>`;
}

// ── Cardio y pasos ──────────────────────────────────────────────────────────
function cardioSheet() {
  const t = fs.readFileSync(path.join(TPL, 'xl/worksheets/sheet6.xml'), 'utf8');
  const head = t.slice(0, t.indexOf('<sheetData>'));
  const rows = [
    `<row r="1" ht="24.0" customHeight="1">${cell('A1', 39, 'CARDIO Y PASOS - BLOQUE 1 (semanas 1-4)')}${cell('B1', 10)}${cell('C1', 10)}${cell('D1', 10)}${cell('E1', 11)}</row>`,
    `<row r="2" ht="18.0" customHeight="1">${cell('A2', 40, 'Semana')}${cell('B2', 40, 'Dia')}${cell('C2', 40, 'Pasos')}${cell('D2', 40, 'Cardio (min)')}${cell('E2', 40, 'Notas')}${cell('G2', 41, 'OBJETIVOS')}${cell('H2', 11)}</row>`,
  ];
  const side = {
    3: ['Pasos diarios', 8000], 4: ['Sesiones cardio / semana', 4], 5: ['Minutos por sesion', 25],
    7: ['Media de pasos', { f: 'IFERROR(AVERAGE(C3:C30),"")', str: true }], 8: ['Total min de cardio', { f: 'IFERROR(SUM(D3:D30),"")' }],
  };
  let r = 3;
  for (let w = 1; w <= 4; w++) for (let d = 1; d <= 7; d++, r++) {
    const odd = r % 2 === 1;
    const [sN, sT] = odd ? [30, 26] : [34, 35];
    const extra = side[r] ? cell(`G${r}`, 42, side[r][0]) + cell(`H${r}`, 27, side[r][1]) : '';
    rows.push(`<row r="${r}"${r > 20 ? ' ht="15.75" customHeight="1"' : ''}>${cell(`A${r}`, sN, w)}${cell(`B${r}`, sN, d)}${cell(`C${r}`, sT)}${cell(`D${r}`, sT)}${cell(`E${r}`, sT)}${extra}</row>`);
  }
  return `${head}<sheetData>${rows.join('')}</sheetData><mergeCells count="2"><mergeCell ref="A1:E1"/><mergeCell ref="G2:H2"/></mergeCells>${TAIL}</worksheet>`;
}

// ── Escribir ────────────────────────────────────────────────────────────────
const W = (rel, content) => { fs.mkdirSync(path.dirname(path.join(OUT, rel)), { recursive: true }); fs.writeFileSync(path.join(OUT, rel), content); };
W('xl/worksheets/sheet1.xml', guideSheet());
DAYS.forEach((d, i) => {
  const { body, rels } = daySheet(d);
  W(`xl/worksheets/sheet${i + 2}.xml`, body);
  W(`xl/worksheets/_rels/sheet${i + 2}.xml.rels`, rels);
});
W('xl/worksheets/sheet6.xml', cardioSheet());
W('xl/sharedStrings.xml', `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sst.length}" uniqueCount="${sst.length}">${sst.map((s) => `<si><t xml:space="preserve">${xml(s)}</t></si>`).join('')}</sst>`);

// Tipos de contenido sin los dibujos.
let ct = fs.readFileSync(path.join(OUT, '[Content_Types].xml'), 'utf8');
ct = ct.replace(/<Override[^>]*drawing\+xml"[^>]*\/>/g, '');
W('[Content_Types].xml', ct);
// Propiedades del documento
const now = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
W('docProps/core.xml', `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Plan de entrenamiento - Bloque 1</dc:title><dcterms:created xsi:type="dcterms:W3CDTF">${now}</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">${now}</dcterms:modified></cp:coreProperties>`);
console.log('ok', sst.length, 'cadenas');
