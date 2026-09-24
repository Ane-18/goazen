// Temporizador de descanso. Guarda la hora de fin (no un contador), así sigue siendo
// correcto aunque bloquees la pantalla o cambies de app.
const KEY = 'goazen:rest';
let bar = null;
let tick = null;
let alerted = false;

const fmt = (s) => `${s < 0 ? '+' : ''}${Math.floor(Math.abs(s) / 60)}:${String(Math.abs(s) % 60).padStart(2, '0')}`;

function read() {
  try { return JSON.parse(sessionStorage.getItem(KEY)); } catch { return null; }
}
function write(v) {
  try { v ? sessionStorage.setItem(KEY, JSON.stringify(v)) : sessionStorage.removeItem(KEY); } catch { /* sin almacenamiento */ }
}

function beep() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.frequency.value = 880;
    g.gain.setValueAtTime(0.25, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
    o.connect(g).connect(ctx.destination);
    o.start();
    o.stop(ctx.currentTime + 0.5);
  } catch { /* sin audio */ }
}

function render() {
  const t = read();
  if (!t) return stop();
  const left = Math.round((t.end - Date.now()) / 1000);
  if (!bar) {
    bar = document.createElement('div');
    bar.className = 'rest-bar';
    bar.setAttribute('role', 'timer');
    bar.innerHTML = `
      <div class="grow">
        <div class="small muted">Descanso</div>
        <div class="row"><span class="time"></span><div class="track"><div class="fill"></div></div></div>
      </div>
      <button class="btn-sm" data-a="-15" aria-label="Quitar 15 segundos">−15</button>
      <button class="btn-sm" data-a="15" aria-label="Añadir 15 segundos">+15</button>
      <button class="btn-sm btn-ghost icon-btn" data-a="x" aria-label="Cerrar temporizador">✕</button>`;
    bar.addEventListener('click', (e) => {
      const a = e.target.closest('[data-a]')?.dataset.a;
      if (!a) return;
      if (a === 'x') return stop();
      const cur = read();
      cur.end += Number(a) * 1000;
      cur.total = Math.max(1, cur.total + Number(a));
      write(cur);
      alerted = cur.end <= Date.now();
      render();
    });
    document.body.appendChild(bar);
  }
  bar.querySelector('.time').textContent = fmt(left);
  bar.querySelector('.fill').style.width = `${Math.max(0, Math.min(100, 100 - (left / t.total) * 100))}%`;
  bar.classList.toggle('over', left <= 0);
  if (left <= 0 && !alerted) {
    alerted = true;
    navigator.vibrate?.([200, 100, 200]);
    beep();
  }
  if (left < -180) stop();
}

export function startRest(seconds) {
  write({ end: Date.now() + seconds * 1000, total: seconds });
  alerted = false;
  clearInterval(tick);
  tick = setInterval(render, 250);
  render();
}

export function stop() {
  write(null);
  clearInterval(tick);
  tick = null;
  bar?.remove();
  bar = null;
}

export function resume() {
  if (read()) {
    alerted = read().end <= Date.now();
    tick = setInterval(render, 250);
    render();
  }
}
