// Ficha de un ejercicio: qué trabaja, cómo se hace, errores típicos y vídeo.
import * as store from './store.js';
import { esc, muscleName, modal, icons } from './ui.js';
import { GUIDES, videoUrl } from './data/guides.js';

export function guideHtml(exerciseId) {
  const ex = store.exercises()[exerciseId];
  const name = ex?.name ?? exerciseId;
  const g = GUIDES[exerciseId];
  const muscles = ex ? [...ex.muscles.p.map((m) => muscleName(m)), ...ex.muscles.s.map((m) => `${muscleName(m)} (ayuda)`)] : [];
  const video = `<a class="btn btn-primary btn-block" href="${esc(videoUrl(g?.video ?? `${name} técnica`))}" target="_blank" rel="noopener">${icons.play} Ver vídeos de cómo se hace</a>`;

  if (!g) {
    return `${muscles.length ? `<p class="small muted">Trabaja: ${esc(muscles.join(', '))}</p>` : ''}
      ${ex?.cue ? `<p>${esc(ex.cue)}</p>` : ''}
      <p class="small faint">Este ejercicio todavía no tiene ficha escrita.</p>
      ${video}`;
  }
  return `<div class="guide stack">
    <div><h3>Qué trabaja</h3><p>${esc(g.works)}</p>
      ${muscles.length ? `<div class="chips">${muscles.map((m) => `<span class="chip">${esc(m)}</span>`).join('')}</div>` : ''}</div>
    <div><h3>Cómo se hace</h3><ol>${g.steps.map((s) => `<li>${esc(s)}</li>`).join('')}</ol></div>
    <div><h3>Errores típicos</h3><ul>${g.mistakes.map((s) => `<li>${esc(s)}</li>`).join('')}</ul></div>
    <div class="note good"><strong>Qué deberías notar:</strong> ${esc(g.feel)}</div>
    ${ex?.cue ? `<div class="note primary"><strong>En tu plan:</strong> ${esc(ex.cue)}</div>` : ''}
    ${video}
    <p class="small faint" style="margin:0">Se abre YouTube con varios vídeos: elige uno de un canal de entrenamiento serio y fíjate en la técnica, no en el peso.</p>
  </div>`;
}

export function showGuide(exerciseId) {
  const name = store.exercises()[exerciseId]?.name ?? exerciseId;
  return modal(
    `<div class="row spread"><h2 style="margin:0">${esc(name)}</h2><button class="btn-ghost icon-btn" data-close aria-label="Cerrar">${icons.x}</button></div>
     <div class="dlg-scroll" style="max-height:70vh">${guideHtml(exerciseId)}</div>`,
    (dlg, close) => (dlg.querySelector('[data-close]').onclick = () => close()),
  );
}
