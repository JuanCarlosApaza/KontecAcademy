/**
 * Prueba rápida del motor de certificados: carga una imagen, dibuja
 * texto encima (con ajuste de línea) y exporta PNG + PDF.
 * Uso: npx tsx tool/test-certificate-render.ts
 */
import { writeFileSync } from 'node:fs';
import { Canvas, GlobalFonts } from '@napi-rs/canvas';
import { PDFDocument } from 'pdf-lib';

// ── Fuentes disponibles en el sistema ──────────────────────────────
const families = GlobalFonts.families.map((f) => f.family);
console.log('Fuentes:', families.slice(0, 30).join(', '));
console.log('total =', families.length);

// Registra fuentes conocidas de Windows si no están.
const wanted: Array<[string, string]> = [
  ['arial', 'C:/Windows/Fonts/arial.ttf'],
  ['arialbd', 'C:/Windows/Fonts/arialbd.ttf'],
  ['times', 'C:/Windows/Fonts/times.ttf'],
  ['timesbd', 'C:/Windows/Fonts/timesbd.ttf'],
  ['georgia', 'C:/Windows/Fonts/georgia.ttf'],
  ['georgiab', 'C:/Windows/Fonts/georgiab.ttf'],
  ['segoeui', 'C:/Windows/Fonts/segoeui.ttf'],
  ['seguisb', 'C:/Windows/Fonts/seguisb.ttf'],
  ['calibri', 'C:/Windows/Fonts/calibri.ttf'],
  ['cambria', 'C:/Windows/Fonts/cambria.ttf'],
];
for (const [alias, path] of wanted) {
  try {
    GlobalFonts.registerFromPath(path, alias);
  } catch (err) {
    console.log('no se pudo registrar', alias, (err as Error).message);
  }
}

// ── Imagen de prueba (generada en local: sin red) ──────────────────
// Simula una plantilla de Canva: banda naranja arriba y fondo gris.
function localTemplate(): Canvas {
  const c = new Canvas(1600, 1130);
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#f4f4f4';
  ctx.fillRect(0, 0, 1600, 1130);
  ctx.fillStyle = '#E8500F';
  ctx.fillRect(0, 0, 1600, 90);
  ctx.fillStyle = '#D9D9D9';
  ctx.fillRect(60, 1050, 1480, 4);
  return c;
}

const template = localTemplate();

const width = template.width;
const height = template.height;
console.log('plantilla:', width, 'x', height);

// ── Dibujo ─────────────────────────────────────────────────────────
const canvas = new Canvas(width, height);
const ctx = canvas.getContext('2d');
ctx.drawImage(template, 0, 0, width, height);

// Ajuste de línea: corta el texto en palabras hasta maxWidth.
function wrap(text: string, maxWidth: number): string[] {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let line = '';
  for (const w of words) {
    const candidate = line.length === 0 ? w : `${line} ${w}`;
    if (ctx.measureText(candidate).width > maxWidth && line.length > 0) {
      lines.push(line);
      line = w;
    } else {
      line = candidate;
    }
  }
  if (line.length > 0) lines.push(line);
  return lines;
}

function drawField(opts: {
  text: string;
  x: number; // 0..1 del ancho
  y: number; // 0..1 (línea base de la primera línea)
  fontSize: number; // px ya escalados
  color: string;
  family: string;
  weight: string;
  align: 'left' | 'center' | 'right';
  maxWidthRatio: number;
}): void {
  ctx.save();
  ctx.font = `${opts.weight} ${opts.fontSize}px ${opts.family}`;
  ctx.fillStyle = opts.color;
  ctx.textBaseline = 'alphabetic';
  ctx.textAlign = opts.align;

  const maxWidth = width * opts.maxWidthRatio;
  const lines = wrap(opts.text, maxWidth);
  const lineHeight = opts.fontSize * 1.25;
  const x = width * opts.x;
  const y = height * opts.y;

  lines.forEach((line, i) => {
    ctx.fillText(line, x, y + i * lineHeight);
  });
  ctx.restore();
}

drawField({
  text: 'Marco Antonio Goyonaga Funes',
  x: 0.5,
  y: 0.44,
  fontSize: height * 0.055,
  color: '#1F3864',
  family: 'georgia',
  weight: 'bold',
  align: 'center',
  maxWidthRatio: 0.7,
});

drawField({
  text: 'Participó satisfactoriamente en el curso de "Modelado, Análisis y Diseño de Estructuras Metálicas Sismorresistentes" con una duración de 120 Horas académicas, Modalidad Virtual en Vivo.',
  x: 0.5,
  y: 0.55,
  fontSize: height * 0.026,
  color: '#111111',
  family: 'segoeui',
  weight: 'normal',
  align: 'center',
  maxWidthRatio: 0.56,
});

// ── Exporta ────────────────────────────────────────────────────────
const png = canvas.toBuffer('image/png');
writeFileSync('tool/_test-cert.png', png);
console.log('PNG:', png.length, 'bytes');

const pdf = await PDFDocument.create();
const embedded = await pdf.embedPng(png);
const page = pdf.addPage([width, height]);
page.drawImage(embedded, { x: 0, y: 0, width, height });
const pdfBytes = await pdf.save();
writeFileSync('tool/_test-cert.pdf', pdfBytes);
console.log('PDF:', pdfBytes.length, 'bytes');
console.log('✓ listo: tool/_test-cert.png y tool/_test-cert.pdf');
