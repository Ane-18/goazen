import * as store from '../store.js';
import { esc, toast, confirmDialog, icons } from '../ui.js';
import { exportExcel, exportBackup, importBackup } from '../export.js';

const THEME_KEY = 'goazen:theme';

export function applyTheme() {
  let t = 'auto';
  try { t = localStorage.getItem(THEME_KEY) ?? 'auto'; } catch { /* sin almacenamiento */ }
  if (t === 'auto') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.dataset.theme = t;
  return t;
}

export function render() {
  const s = store.get().settings;
  let theme = 'auto';
  try { theme = localStorage.getItem(THEME_KEY) ?? 'auto'; } catch { /* sin almacenamiento */ }
  const n = store.finishedSessions().length;
  return `<h1>Más</h1>
    <a class="card list-link" href="#/ciencia" style="display:flex">
      <span class="grow"><strong>La ciencia detrás</strong><br><span class="small muted">Qué hace la app, por qué, y qué no hace</span></span><span class="faint" style="transform:rotate(180deg)">${icons.back}</span>
    </a>

    <div class="card stack">
      <h2>Ajustes</h2>
      <div class="row">
        <label class="field grow"><span>Descanso compuestos (s)</span><input data-s="restCompound" type="number" inputmode="numeric" value="${s.restCompound}"></label>
        <label class="field grow"><span>Descanso aislamiento (s)</span><input data-s="restIsolation" type="number" inputmode="numeric" value="${s.restIsolation}"></label>
      </div>
      <div class="row">
        <label class="field grow"><span>Pasos diarios</span><input data-s="stepsGoal" type="number" inputmode="numeric" step="500" value="${s.stepsGoal}"></label>
        <label class="field grow"><span>Días de cardio/sem</span><input data-s="cardioSessionsGoal" type="number" inputmode="numeric" value="${s.cardioSessionsGoal}"></label>
      </div>
      <label class="field"><span>Tema</span><select id="theme">
        <option value="auto" ${theme === 'auto' ? 'selected' : ''}>Automático</option>
        <option value="dark" ${theme === 'dark' ? 'selected' : ''}>Oscuro</option>
        <option value="light" ${theme === 'light' ? 'selected' : ''}>Claro</option>
      </select></label>
    </div>

    <div class="card stack">
      <h2>Tus datos</h2>
      <p class="small muted">${n} sesiones guardadas. Todo se queda en este móvil: no hay servidor ni cuentas. Haz una copia de vez en cuando por si cambias de móvil o borras el navegador.</p>
      <button class="btn-block" data-a="excel">Exportar a Excel</button>
      <button class="btn-block" data-a="backup">Descargar copia de seguridad</button>
      <label class="btn btn-block">Restaurar copia<input type="file" accept="application/json,.json" data-a="restore" class="hidden"></label>
      <button class="btn-danger btn-block" data-a="reset">Borrar todo y empezar de cero</button>
    </div>
    <p class="small faint" style="text-align:center">Goazen · v${esc(window.GOAZEN_VERSION ?? '')}</p>`;
}

export function mount(root, rerender) {
  root.querySelectorAll('[data-s]').forEach((el) => (el.onchange = () => {
    const v = Number(el.value.replace(',', '.'));
    if (!Number.isFinite(v)) return;
    store.update((st) => (st.settings[el.dataset.s] = v));
    toast('Guardado');
  }));
  root.querySelector('#theme').onchange = (e) => {
    try { localStorage.setItem(THEME_KEY, e.target.value); } catch { /* sin almacenamiento */ }
    applyTheme();
  };
  root.querySelector('[data-a=excel]').onclick = async () => {
    try { await exportExcel(); } catch (e) { toast('No se pudo exportar: ' + e.message); }
  };
  root.querySelector('[data-a=backup]').onclick = exportBackup;
  root.querySelector('[data-a=restore]').onchange = async (e) => {
    const f = e.target.files[0];
    if (!f) return;
    if (!(await confirmDialog('Esto reemplaza todos los datos actuales por los de la copia. ¿Seguir?', { ok: 'Restaurar', danger: true }))) return;
    try { await importBackup(f); toast('Copia restaurada'); rerender(); } catch (err) { toast(err.message); }
  };
  root.querySelector('[data-a=reset]').onclick = async () => {
    if (!(await confirmDialog('¿Borrar todos tus registros? Se vuelve al estado inicial (Bloque 3 + historial del Excel). Descarga antes una copia si la quieres.', { ok: 'Borrar todo', danger: true }))) return;
    store.resetAll();
    toast('Datos reiniciados');
    location.hash = '#/';
  };
}

export function renderScience() {
  const sec = (title, body) => `<div class="card stack"><h2>${title}</h2>${body}</div>`;
  return `<a href="#/mas" class="btn btn-ghost icon-btn" aria-label="Volver">${icons.back}</a>
  <h1>La ciencia detrás</h1>
  <p class="muted">Cada decisión de la app se basa en revisiones y metaanálisis, no en un solo estudio. Cuando la evidencia es débil, la app no lo aplica.</p>

  ${sec('1. Ejercicios fijos y sobrecarga progresiva', `
    <p>El músculo crece si el estímulo aumenta con el tiempo. Para medirlo hay que <strong>repetir los mismos ejercicios</strong> durante un bloque: si cambian cada semana, no sabes si progresas.</p>
    <p>La app usa <strong>doble progresión</strong>: con el mismo peso intentas sumar repeticiones hasta el máximo del rango; cuando lo consigues en todas las series, sube el peso y vuelves al mínimo. Progresar por carga o por repeticiones da una hipertrofia similar (Plotkin et al. 2022). El incremento se ajusta a lo que permite tu gimnasio, sin porcentajes imposibles como 4,1 kg.</p>`)}

  ${sec('2. RIR: cuánto te queda en el tanque', `
    <p>RIR = repeticiones en reserva. Acabar las series a 0–3 RIR produce una hipertrofia similar a llegar al fallo, con menos fatiga (Refalo et al. 2023). La app usa RIR 1–2 como objetivo. Si anotas RIR 3 o más, entiende que el peso es ligero y te propone subir.</p>
    <p class="small muted">Escala RIR: Zourdos et al. 2016; Helms et al. 2016.</p>`)}

  ${sec('3. Volumen: series por músculo y semana', `
    <p>Más series semanales dan más crecimiento, con rendimientos decrecientes. <strong>10 series o más</strong> por músculo es una referencia sólida (Schoenfeld et al. 2017). La app cuenta las series de los ejercicios principales como 1 y las de los secundarios como 0,5, como en el metaanálisis más reciente (Pelland et al. 2024).</p>
    <p>Entrenar cada músculo <strong>2 veces por semana</strong> ayuda a repartir ese volumen (Schoenfeld et al. 2016). Tu reparto torso/pierna lo cumple.</p>`)}

  ${sec('4. Rangos de repeticiones', `
    <p>Entre ~6 y ~30 repeticiones se gana músculo de forma similar si las series se acercan al fallo; los rangos bajos ganan más fuerza (Schoenfeld et al. 2017, cargas altas vs. bajas).</p>
    <p>Tu Bloque 3 alterna 6–8 y 10–12: es razonable y ayuda a la fuerza. Periodizar mejora algo la fuerza, pero <strong>no la hipertrofia</strong> frente a no periodizar (Moesgaard et al. 2022). Así que la ventaja es real, pero pequeña: lo importante sigue siendo progresar y acumular series.</p>`)}

  ${sec('5. Descansos', `
    <p>Descansar más de 1 minuto mejora ligeramente la hipertrofia, sobre todo en ejercicios compuestos (Schoenfeld et al. 2016; Singer et al. 2024). Por defecto la app usa 2:30 en compuestos y 1:30 en aislamiento; puedes cambiarlo.</p>`)}

  ${sec('6. Cardio y pasos', `
    <p>Hacer cardio además de pesas no frena la ganancia de músculo ni de fuerza en general (Schumann et al. 2022). Para que interfiera lo menos posible: caminar o bici mejor que correr los días de pierna (Wilson et al. 2012), y si lo haces el mismo día, después de las pesas o separado unas horas.</p>
    <p>Los pasos suman actividad con muy poca fatiga. Con 4 días de cardio y pasos diarios tienes una base muy completa.</p>`)}

  ${sec('7. Lo que la app ya no hace, y por qué', `
    <ul>
      <li><strong>Ajustar el entrenamiento según la fase del ciclo.</strong> Los metaanálisis encuentran efectos triviales o nulos del ciclo sobre la fuerza y la adaptación (McNulty et al. 2020; Colenso-Semple et al. 2023). Si un día te encuentras peor, marca cómo te sientes y ajusta ese día. No hace falta un calendario fijo.</li>
      <li><strong>Deload automático por RPE alto.</strong> Entrenar a RIR 1–2 es un RPE de 8–9 a propósito: la regla anterior te habría hecho descargar casi siempre. Un deload de una semana no mejoró la hipertrofia en un ensayo reciente (Coleman et al. 2024). Si te notas acumulando fatiga, baja series una semana.</li>
      <li><strong>Prohibir entrenar si dormiste poco.</strong> Dormir mal empeora el rendimiento, pero no convierte la sesión en inútil. Si ha sido una mala noche, quita una serie por ejercicio o deja 1–2 reps más en reserva.</li>
      <li><strong>Ejercicios aleatorios.</strong> Impedían comparar semanas.</li>
    </ul>`)}

  <div class="card"><h2>Referencias</h2><ol class="refs">
    <li>Coleman M. et al. (2024). Gaining more from doing less? The effects of a one-week deload period during supervised resistance training. <em>PeerJ</em>.</li>
    <li>Colenso-Semple L.M. et al. (2023). Current evidence shows no influence of women's menstrual cycle phase on acute strength performance or adaptations to resistance exercise training. <em>Front. Sports Act. Living</em>.</li>
    <li>Helms E.R. et al. (2016). Application of the repetitions in reserve-based rating of perceived exertion scale for resistance training. <em>Strength Cond. J.</em></li>
    <li>McNulty K.L. et al. (2020). The effects of menstrual cycle phase on exercise performance in eumenorrheic women. <em>Sports Med.</em></li>
    <li>Moesgaard L. et al. (2022). Effects of periodization on strength and muscle hypertrophy in volume-equated resistance training programs. <em>Sports Med.</em></li>
    <li>Pelland J.C. et al. (2024). The resistance training dose-response: meta-regressions exploring the effects of weekly volume and frequency on muscle hypertrophy and strength gain. <em>SportRxiv</em> (preprint).</li>
    <li>Plotkin D. et al. (2022). Progressive overload without progressing load? The effects of load or repetition progression on muscular adaptations. <em>PeerJ</em>.</li>
    <li>Refalo M.C. et al. (2023). Influence of resistance training proximity-to-failure on skeletal muscle hypertrophy. <em>Sports Med.</em></li>
    <li>Schumann M. et al. (2022). Compatibility of concurrent aerobic and strength training for skeletal muscle size and function: an updated systematic review and meta-analysis. <em>Sports Med.</em></li>
    <li>Schoenfeld B.J. et al. (2016). Effects of resistance training frequency on measures of muscle hypertrophy. <em>Sports Med.</em></li>
    <li>Schoenfeld B.J. et al. (2016). Longer interset rest periods enhance muscle strength and hypertrophy in resistance-trained men. <em>J. Strength Cond. Res.</em></li>
    <li>Schoenfeld B.J., Ogborn D., Krieger J.W. (2017). Dose-response relationship between weekly resistance training volume and increases in muscle mass. <em>J. Sports Sci.</em></li>
    <li>Schoenfeld B.J. et al. (2017). Strength and hypertrophy adaptations between low- vs. high-load resistance training. <em>J. Strength Cond. Res.</em></li>
    <li>Singer A. et al. (2024). Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest interval duration on muscle hypertrophy. <em>Front. Sports Act. Living</em>.</li>
    <li>Wilson J.M. et al. (2012). Concurrent training: a meta-analysis examining interference of aerobic and resistance exercises. <em>J. Strength Cond. Res.</em></li>
    <li>Zourdos M.C. et al. (2016). Novel resistance training-specific RPE scale measuring repetitions in reserve. <em>J. Strength Cond. Res.</em></li>
  </ol></div>
  <p class="small faint">Herramienta educativa. No sustituye a un profesional sanitario. Si algo duele (no confundir con agujetas), para y consúltalo.</p>`;
}
