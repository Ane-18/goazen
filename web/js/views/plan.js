import * as store from '../store.js';
import { esc, muscleName, rangeText, icons, modal, confirmDialog, toast } from '../ui.js';
import { blockVolume, pickExercise } from '../coach.js';
import { volumeStatus, fmt } from '../progression.js';
import { MUSCLES } from '../data/exercises.js';
import { loadXlsx } from '../export.js';
import { parseBlock } from '../importer.js';

let selectedWeek = null;


export function render() {
  const block = store.activeBlock();
  const ex = store.exercises();
  if (!block.weeks.includes(selectedWeek)) selectedWeek = store.nextSlot(block)?.week ?? block.weeks[0];

  let html = `<h1>${esc(block.name)}</h1>
    <div class="chips" role="tablist" style="margin:12px 0">${block.weeks.map((w) =>
      `<button class="chip ${w === selectedWeek ? 'on' : ''}" data-week="${w}" role="tab" aria-selected="${w === selectedWeek}">Semana ${w}</button>`).join('')}</div>`;

  for (const d of block.days) {
    html += `<div class="card"><div class="row spread"><div><h2 style="margin:0">${esc(d.name)}</h2><div class="small muted">${esc(d.subtitle)}</div></div></div>
      <ul class="list" style="margin-top:10px">${d.items.map((it, i) => `
        <li><button class="btn-block" style="background:transparent;padding:0;justify-content:flex-start;text-align:left" data-item="${d.id}|${i}">
          <span class="grow"><span>${esc(ex[it.exerciseId]?.name ?? it.exerciseId)}${it.optional ? ' <span class="chip">opcional</span>' : ''}</span><br>
          <span class="small muted num">${rangeText(it.sets)} × ${rangeText(it.reps[selectedWeek] ?? [0, 0])} reps</span>${it.note ? `<br><span class="small faint">${esc(it.note)}</span>` : ''}</span>
          <span class="faint">${icons.edit}</span>
        </button></li>`).join('')}
      </ul>
    </div>`;
  }

  html += `<p class="small faint" style="margin:12px 4px">Toca un ejercicio para cambiar series, repeticiones o sustituirlo.</p>`;
  html += volumeCard(block);

  const changes = [...(block.changes ?? [])].reverse();
  if (changes.length) {
    html += `<details class="card"><summary><strong>Cambios en este bloque</strong></summary><ul class="list" style="margin-top:10px">${changes.map((c) => `
      <li class="small"><strong>Sem. ${c.week}:</strong> ${c.from ? esc(ex[c.from]?.name ?? c.from) + ' → ' : 'Nuevo: '}${esc(ex[c.to]?.name ?? c.to)}
      ${c.reason ? `<br><span class="muted">${esc(c.reason)}</span>` : ''}</li>`).join('')}</ul></details>`;
  }

  const others = store.get().blocks.filter((b) => b.id !== block.id);
  html += `<div class="card stack">
    <h2 style="margin:0">¿Empiezas un bloque nuevo?</h2>
    <label class="btn btn-primary btn-block">Importar bloque desde Excel<input type="file" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" class="hidden" data-import></label>
    <button class="btn-block" data-new-block>Copiar este bloque y cambiarlo aquí</button>
  </div>`;
  html += `<details class="card"><summary><strong>Añadir ejercicios y otros bloques</strong></summary><div class="stack" style="margin-top:10px">
    <div class="row wrap">${block.days.map((d) => `<button class="btn-sm" data-add="${d.id}">${icons.plus} ${esc(d.name)}</button>`).join('')}</div>
    ${others.length ? `<ul class="list">${others.map((b) => `<li class="row spread"><span>${esc(b.name)} <span class="small muted">· semanas ${b.weeks[0]}–${b.weeks[b.weeks.length - 1]}</span></span>
      ${b.archived ? '<span class="chip">histórico</span>' : `<button class="btn-sm" data-activate="${b.id}">Activar</button>`}</li>`).join('')}</ul>` : ''}
  </div></details>`;
  return html;
}

function volumeCard(block) {
  const { min, max } = blockVolume(block);
  const muscles = Object.keys(MUSCLES).filter((m) => (max[m] ?? 0) > 0);
  const scale = Math.max(24, ...muscles.map((m) => max[m]));
  const pct = (v) => `${(v / scale) * 100}%`;
  const rows = muscles.map((m) => {
    return `<div class="vol-row">
      <span>${esc(muscleName(m))}</span>
      <div class="vol-track" title="${fmt(min[m])}–${fmt(max[m])} series">
        <div class="band" style="left:${pct(10)};width:${pct(10)}"></div>
        <div class="range" style="left:0;width:${pct(max[m])}"></div>
        <div class="bar" style="left:0;width:${pct(min[m] ?? 0)}"></div>
      </div>
      <span class="num small" style="text-align:right">${fmt(min[m])}${max[m] !== min[m] ? '–' + fmt(max[m]) : ''}</span>
    </div>`;
  }).join('');
  const ticks = [0, 10, 20].filter((t) => t <= scale).map((t) => `<span style="left:${pct(t)}">${t}</span>`).join('');
  const low = muscles.filter((m) => ['low', 'fair'].includes(volumeStatus(min[m])) && m !== 'hombro_ant' && m !== 'abdomen');
  const high = muscles.filter((m) => volumeStatus(min[m]) === 'high');

  return `<details class="card"><summary><strong>Series por músculo a la semana</strong>${low.length ? ' <span class="chip warn">revisar</span>' : ''}</summary><div class="stack" style="margin-top:10px">
    <p class="small muted">Lo recomendable es 10–20 series por músculo a la semana (zona gris).</p>
    <div>${rows}<div class="vol-axis"><span></span><div class="ticks">${ticks}</div><span></span></div></div>
    ${low.length ? `<div class="note warn small">Poco volumen en: ${low.map((m) => esc(muscleName(m))).join(', ')}.
      ${low.includes('hombro_lat') ? 'Idea: añade elevación lateral también el Día 3. ' : ''}${low.includes('pecho') ? 'Idea: haz 4 series en los dos press. ' : ''}</div>` : ''}
    ${high.length ? `<p class="small muted">${high.map((m) => esc(muscleName(m))).join(', ')} por encima de 20: es tu prioridad; si recuperas bien, está bien.</p>` : ''}
  </div></details>`;
}

export function mount(root, rerender) {
  root.querySelectorAll('[data-week]').forEach((b) => (b.onclick = () => { selectedWeek = Number(b.dataset.week); rerender(); }));
  root.querySelectorAll('[data-item]').forEach((b) => (b.onclick = () => {
    const [dayId, i] = b.dataset.item.split('|');
    editItem(dayId, Number(i), rerender);
  }));
  root.querySelectorAll('[data-add]').forEach((b) => (b.onclick = async () => {
    const block = store.activeBlock();
    const day = block.days.find((d) => d.id === b.dataset.add);
    const id = await pickExercise({ title: `Añadir a ${day.name}`, exclude: day.items.map((i) => i.exerciseId) });
    if (!id) return;
    store.update(() => {
      day.items.push({ exerciseId: id, sets: [3, 3], reps: Object.fromEntries(block.weeks.map((w) => [w, [12, 15]])), note: '', optional: false });
      block.changes = [...(block.changes ?? []), { week: store.nextSlot(block)?.week ?? block.weeks[0], date: store.today(), from: null, to: id, reason: '' }];
    });
    editItem(day.id, day.items.length - 1, rerender);
  }));
  root.querySelectorAll('[data-activate]').forEach((b) => (b.onclick = () => {
    store.update((st) => (st.activeBlockId = b.dataset.activate));
    rerender();
  }));
  root.querySelector('[data-new-block]').onclick = () => newBlock(rerender);
  root.querySelector('[data-import]').onchange = (e) => {
    const f = e.target.files[0];
    e.target.value = '';
    if (f) importFromExcel(f, rerender);
  };
}

async function editItem(dayId, i, rerender) {
  const block = store.activeBlock();
  const day = block.days.find((d) => d.id === dayId);
  const it = day.items[i];
  const ex = store.exercises()[it.exerciseId];
  const res = await modal(
    `<div class="row spread"><h2 style="margin:0">${esc(ex?.name ?? it.exerciseId)}</h2><button class="btn-ghost icon-btn" data-a="close" aria-label="Cerrar">✕</button></div>
     <div class="row">
       <label class="field grow"><span>Series mín.</span><input name="s0" type="number" min="1" max="10" value="${it.sets[0]}" inputmode="numeric"></label>
       <label class="field grow"><span>Series máx.</span><input name="s1" type="number" min="1" max="10" value="${it.sets[1]}" inputmode="numeric"></label>
     </div>
     <div class="row wrap">${block.weeks.map((w) => `<label class="field" style="flex:1 1 40%"><span>Reps semana ${w}</span><input name="w${w}" value="${(it.reps[w] ?? [10, 12]).join('-')}" placeholder="8-10"></label>`).join('')}</div>
     <label class="field"><span>Nota</span><input name="note" value="${esc(it.note)}"></label>
     <label class="row"><input type="checkbox" name="opt" style="width:auto;min-height:0" ${it.optional ? 'checked' : ''}><span>Opcional</span></label>
     <div class="row wrap">
       <button class="btn-sm" data-a="up" ${i === 0 ? 'disabled' : ''}>${icons.up} Subir</button>
       <button class="btn-sm" data-a="down" ${i === day.items.length - 1 ? 'disabled' : ''}>${icons.down} Bajar</button>
       <button class="btn-sm" data-a="swap">${icons.swap} Sustituir</button>
       <button class="btn-sm btn-danger" data-a="remove">Quitar</button>
     </div>
     <button class="btn-primary" data-a="save">Guardar</button>`,
    (dlg, close) => {
      dlg.querySelectorAll('[data-a]').forEach((b) => (b.onclick = () => {
        const a = b.dataset.a;
        if (a !== 'save') return close({ a });
        const v = (n) => dlg.querySelector(`[name=${n}]`).value;
        const reps = {};
        for (const w of block.weeks) {
          const m = v('w' + w).match(/(\d+)\s*[-–]\s*(\d+)|(\d+)/);
          if (!m) return toast(`Rango de la semana ${w} no válido`);
          reps[w] = m[3] ? [Number(m[3]), Number(m[3])] : [Number(m[1]), Number(m[2])].sort((x, y) => x - y);
        }
        const s0 = Math.max(1, Number(v('s0')) || 1);
        const s1 = Math.max(s0, Number(v('s1')) || s0);
        close({ a, sets: [s0, s1], reps, note: v('note'), optional: dlg.querySelector('[name=opt]').checked });
      }));
    },
  );
  if (!res || res.a === 'close') return;
  if (res.a === 'save') {
    store.update(() => Object.assign(it, { sets: res.sets, reps: res.reps, note: res.note, optional: res.optional }));
  } else if (res.a === 'up' || res.a === 'down') {
    const j = res.a === 'up' ? i - 1 : i + 1;
    store.update(() => ([day.items[i], day.items[j]] = [day.items[j], day.items[i]]));
  } else if (res.a === 'remove') {
    if (!(await confirmDialog(`¿Quitar ${ex?.name} del ${day.name}? Su historial se conserva.`, { ok: 'Quitar', danger: true }))) return;
    store.update(() => day.items.splice(i, 1));
  } else if (res.a === 'swap') {
    const to = await pickExercise({ title: `Sustituir ${ex?.name}`, preferMuscles: ex?.muscles.p ?? [], exclude: [it.exerciseId] });
    if (!to) return;
    const reason = await modal(
      `<h2>¿Por qué lo cambias?</h2><textarea name="r" placeholder="Molestia, estancada, no lo siento…"></textarea>
       <button class="btn-primary" data-ok>Guardar</button>`,
      (dlg, close) => (dlg.querySelector('[data-ok]').onclick = () => close(dlg.querySelector('[name=r]').value.trim())),
    );
    store.update(() => {
      block.changes = [...(block.changes ?? []), { week: store.nextSlot(block)?.week ?? block.weeks[0], date: store.today(), from: it.exerciseId, to, reason: reason ?? '' }];
      it.exerciseId = to;
    });
  }
  rerender();
}

async function newBlock(rerender) {
  const cur = store.activeBlock();
  const start = Math.max(...store.get().blocks.flatMap((b) => b.weeks)) + 1;
  const res = await modal(
    `<h2>Bloque nuevo</h2>
     <label class="field"><span>Nombre</span><input name="name" value="Bloque ${store.get().blocks.filter((b) => !b.archived).length + 3}"></label>
     <div class="row">
       <label class="field grow"><span>Primera semana</span><input name="start" type="number" value="${start}" inputmode="numeric"></label>
       <label class="field grow"><span>Nº de semanas</span><input name="n" type="number" value="4" min="2" max="8" inputmode="numeric"></label>
     </div>
     <label class="field"><span>Rangos de repeticiones de los principales</span><select name="scheme">
       <option value="copy">Igual que la última semana de ${esc(cur.name)}</option>
       <option value="sh">Fuerza → hipertrofia (6–8 la 1.ª mitad, 10–12 la 2.ª)</option>
       <option value="h">Hipertrofia (8–12 todo el bloque)</option>
     </select></label>
     <p class="small faint">Se copian los ejercicios de ${esc(cur.name)}. Después podrás cambiar los que quieras. Los accesorios (12+ reps) mantienen su rango.</p>
     <div class="row" style="justify-content:flex-end"><button class="btn-ghost" data-c>Cancelar</button><button class="btn-primary" data-ok>Crear</button></div>`,
    (dlg, close) => {
      dlg.querySelector('[data-c]').onclick = () => close(null);
      dlg.querySelector('[data-ok]').onclick = () => close({
        name: dlg.querySelector('[name=name]').value.trim() || 'Bloque nuevo',
        start: Number(dlg.querySelector('[name=start]').value) || start,
        n: Math.min(8, Math.max(2, Number(dlg.querySelector('[name=n]').value) || 4)),
        scheme: dlg.querySelector('[name=scheme]').value,
      });
    },
  );
  if (!res) return;
  const weeks = Array.from({ length: res.n }, (_, k) => res.start + k);
  const lastWeek = cur.weeks[cur.weeks.length - 1];
  const block = {
    id: 'b' + store.uid(),
    name: res.name,
    weeks,
    startDate: store.today(),
    rir: cur.rir ?? [1, 2],
    description: { copy: 'Mismos rangos que el bloque anterior.', sh: 'Primera mitad: fuerza (6–8). Segunda mitad: hipertrofia (10–12).', h: 'Hipertrofia: 8–12 reps en los principales.' }[res.scheme],
    days: cur.days.map((d) => ({
      ...d,
      items: d.items.map((it) => {
        const base = it.reps[lastWeek] ?? Object.values(it.reps)[0];
        const main = base[0] < 12;
        const reps = Object.fromEntries(weeks.map((w, k) => {
          if (!main || res.scheme === 'copy') return [w, base];
          if (res.scheme === 'h') return [w, [8, 12]];
          return [w, k < res.n / 2 ? [6, 8] : [10, 12]];
        }));
        return { ...it, reps: structuredClone(reps), sets: [...it.sets] };
      }),
    })),
    changes: [],
  };
  store.update((st) => {
    st.blocks.push(block);
    st.activeBlockId = block.id;
  });
  selectedWeek = weeks[0];
  toast(`${block.name} creado`);
  rerender();
}

function nextMonday() {
  const d = new Date(`${store.today()}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + ((8 - d.getUTCDay()) % 7 || 7));
  return d.toISOString().slice(0, 10);
}

async function importFromExcel(file, rerender) {
  let parsed;
  let name = 'Bloque nuevo';
  try {
    const XLSX = await loadXlsx();
    const wb = XLSX.read(new Uint8Array(await file.arrayBuffer()), { type: 'array' });
    const sheets = Object.fromEntries(wb.SheetNames.map((n) => [n, XLSX.utils.sheet_to_json(wb.Sheets[n], { header: 1, defval: '' })]));
    const lastWeek = Math.max(0, ...store.get().blocks.flatMap((b) => b.weeks));
    parsed = parseBlock(sheets, store.exercises(), [1, 2, 3, 4].map((k) => lastWeek + k));
    const title = Object.values(sheets).flat().flat().map(String).find((c) => /bloque\s*\d+/i.test(c));
    if (title) name = 'Bloque ' + title.match(/bloque\s*(\d+)/i)[1];
  } catch (err) {
    console.error(err);
    return toast('No he podido leer el Excel: ' + err.message);
  }
  if (!parsed.days.some((d) => d.items.length)) {
    return toast(parsed.warnings[0] ?? 'No he encontrado ejercicios en el Excel.');
  }

  const ex = store.exercises();
  const newIds = new Set(parsed.newExercises.map((e) => e.id));
  const exName = (id) => ex[id]?.name ?? parsed.newExercises.find((e) => e.id === id)?.name ?? id;
  const res = await modal(
    `<h2 style="margin:0">Importar bloque</h2>
     <div class="row">
       <label class="field grow"><span>Nombre</span><input name="name" value="${esc(name)}"></label>
       <label class="field grow"><span>Empiezas el</span><input name="start" type="date" value="${nextMonday()}"></label>
     </div>
     <p class="small muted">Semanas ${parsed.weeks[0]}–${parsed.weeks[parsed.weeks.length - 1]}. Revisa que cada ejercicio es el correcto; si alguno no lo es, lo cambias después tocándolo en el plan.</p>
     <div class="dlg-scroll">${parsed.days.map((d) => `<h3 style="margin-top:10px">${esc(d.name)}</h3><ul class="list">${d.items.map((it) => `
       <li class="small">${esc(exName(it.exerciseId))}${newIds.has(it.exerciseId) ? ' <span class="chip info">nuevo</span>' : ''}
       <br><span class="faint">${rangeText(it.sets)} × ${[...new Set(parsed.weeks.map((w) => rangeText(it.reps[w])))].join(' → ')} reps</span></li>`).join('')}</ul>`).join('')}
     ${parsed.warnings.length ? `<div class="note warn small">${parsed.warnings.map(esc).join('<br>')}</div>` : ''}</div>
     <div class="row" style="justify-content:flex-end"><button class="btn-ghost" data-c>Cancelar</button><button class="btn-primary" data-ok>Crear bloque</button></div>`,
    (dlg, close) => {
      dlg.querySelector('[data-c]').onclick = () => close(null);
      dlg.querySelector('[data-ok]').onclick = () => close({
        name: dlg.querySelector('[name=name]').value.trim() || name,
        start: dlg.querySelector('[name=start]').value || nextMonday(),
      });
    },
  );
  if (!res) return;

  const block = {
    id: 'b' + store.uid(),
    name: res.name,
    weeks: parsed.weeks,
    startDate: res.start,
    rir: store.activeBlock()?.rir ?? [1, 2],
    description: '',
    days: parsed.days.map((d) => ({ ...d, items: d.items.map(({ sourceName, ...it }) => it) })),
    changes: [],
  };
  store.update((st) => {
    for (const e of parsed.newExercises) if (!st.customExercises.some((c) => c.id === e.id)) st.customExercises.push(e);
    st.blocks.push(block);
    st.activeBlockId = block.id;
  });
  selectedWeek = block.weeks[0];
  toast(`${block.name} importado`);
  rerender();
}
