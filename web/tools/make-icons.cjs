// Genera icons/icon-192.png e icons/icon-512.png (mismo dibujo que icon.svg) sin dependencias.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const BG = [0xff, 0x6b, 0x2b];
const FG = [0x1a, 0x0a, 0x02];
// Rectángulos redondeados en coordenadas de 512 px: [x, y, w, h, r]
const SHAPES = [
  [96, 176, 48, 160, 14], [368, 176, 48, 160, 14],
  [152, 208, 36, 96, 10], [324, 208, 36, 96, 10],
  [188, 240, 136, 32, 8],
];

function inRoundRect(px, py, [x, y, w, h, r]) {
  const cx = Math.min(Math.max(px, x + r), x + w - r);
  const cy = Math.min(Math.max(py, y + r), y + h - r);
  return px >= x && px <= x + w && py >= y && py <= y + h && (px - cx) ** 2 + (py - cy) ** 2 <= r * r;
}

function crc32(buf) {
  let c, crc = 0xffffffff;
  for (let n = 0; n < buf.length; n++) {
    c = (crc ^ buf[n]) & 0xff;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    crc = (crc >>> 8) ^ c;
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}

function png(size, maskable) {
  const S = 4; // supersampling para bordes suaves
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0;
    for (let x = 0; x < size; x++) {
      let bg = 0, fg = 0;
      for (let sy = 0; sy < S; sy++) for (let sx = 0; sx < S; sx++) {
        const px = ((x + (sx + 0.5) / S) / size) * 512;
        const py = ((y + (sy + 0.5) / S) / size) * 512;
        if (!maskable && !inRoundRect(px, py, [0, 0, 512, 512, 112])) continue;
        if (SHAPES.some((s) => inRoundRect(px, py, s))) fg++; else bg++;
      }
      const n = S * S, a = (bg + fg) / n;
      const o = y * (size * 4 + 1) + 1 + x * 4;
      for (let c = 0; c < 3; c++) raw[o + c] = a ? Math.round((BG[c] * bg + FG[c] * fg) / (bg + fg)) : 0;
      raw[o + 3] = Math.round(a * 255);
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0); ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
  ]);
}

const dir = path.join(__dirname, '..', 'icons');
fs.writeFileSync(path.join(dir, 'icon-192.png'), png(192, false));
// 512 cuadrado completo: sirve también como icono "maskable" (Android recorta la forma).
fs.writeFileSync(path.join(dir, 'icon-512.png'), png(512, true));
console.log('Iconos generados');
