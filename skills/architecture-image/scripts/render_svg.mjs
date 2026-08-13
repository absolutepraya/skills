#!/usr/bin/env node
// Render an SVG to PNG using @resvg/resvg-js (crisp text, system fonts).
// Usage: node render_svg.mjs <input.svg> <output.png> [--width N]
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname } from 'node:path';
import { Resvg } from '@resvg/resvg-js';

const [, , input, output, ...rest] = process.argv;
if (!input || !output) {
  console.error('Usage: node render_svg.mjs <input.svg> <output.png> [--width N]');
  process.exit(1);
}
if (!existsSync(input)) {
  console.error(`SVG not found: ${input}`);
  process.exit(1);
}

let width;
for (let i = 0; i < rest.length; i++) {
  if (rest[i] === '--width') width = parseInt(rest[i + 1], 10);
}

const svg = readFileSync(input);
const opts = { font: { loadSystemFonts: true } };
if (width) opts.fitTo = { mode: 'width', value: width };

const png = new Resvg(svg, opts).render().asPng();
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, png);
console.log(`Rendered ${input} -> ${output} (${png.length} bytes)`);
