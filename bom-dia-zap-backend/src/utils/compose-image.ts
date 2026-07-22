import axios from 'axios';
import { randomUUID } from 'crypto';
import * as path from 'path';
import sharp from 'sharp';

const CANVAS_WIDTH = 1080;
const CANVAS_HEIGHT = 1350;
const MAX_CHARS_PER_LINE = 26;
const FONT_SIZE = 56;
const BRAND = 'Bom Dia Zap';

function escapeXml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function wrapText(text: string, maxCharsPerLine: number): string[] {
  const words = text.split(' ');
  const lines: string[] = [];
  let currentLine = '';

  for (const word of words) {
    const candidate = currentLine ? `${currentLine} ${word}` : word;

    if (candidate.length > maxCharsPerLine && currentLine) {
      lines.push(currentLine);
      currentLine = word;
    } else {
      currentLine = candidate;
    }
  }

  if (currentLine) {
    lines.push(currentLine);
  }

  return lines;
}

function buildOverlaySvg(phrase: string): Buffer {
  const lines = wrapText(phrase, MAX_CHARS_PER_LINE);
  const lineHeight = FONT_SIZE * 1.3;
  const textBlockHeight = lines.length * lineHeight;
  const startY = CANVAS_HEIGHT - 220 - textBlockHeight;

  const tspans = lines
    .map(
      (line, index) =>
        `<tspan x="${CANVAS_WIDTH / 2}" dy="${index === 0 ? 0 : lineHeight}">${escapeXml(line)}</tspan>`,
    )
    .join('');

  const svg = `
    <svg width="${CANVAS_WIDTH}" height="${CANVAS_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="scrim" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#000000" stop-opacity="0"/>
          <stop offset="100%" stop-color="#000000" stop-opacity="0.8"/>
        </linearGradient>
      </defs>
      <rect x="0" y="${CANVAS_HEIGHT * 0.42}" width="${CANVAS_WIDTH}" height="${CANVAS_HEIGHT * 0.58}" fill="url(#scrim)"/>
      <text x="${CANVAS_WIDTH / 2}" y="${startY}" font-family="Arial, sans-serif" font-size="${FONT_SIZE}" font-weight="700" fill="#ffffff" text-anchor="middle">
        ${tspans}
      </text>
      <text x="${CANVAS_WIDTH / 2}" y="${CANVAS_HEIGHT - 40}" font-family="Arial, sans-serif" font-size="28" fill="#ffffff" fill-opacity="0.85" text-anchor="middle">
        ${escapeXml(BRAND)}
      </text>
    </svg>
  `;

  return Buffer.from(svg);
}

/**
 * Baixa uma foto de banco de imagens e compõe a frase por cima, gerando o
 * cartão final (original + thumbnail) que o app vai servir.
 */
export async function composeImage(photoUrl: string, phrase: string) {
  const response = await axios({
    url: photoUrl,
    method: 'GET',
    responseType: 'arraybuffer',
  });

  const base = await sharp(response.data as Buffer)
    .resize({
      width: CANVAS_WIDTH,
      height: CANVAS_HEIGHT,
      fit: 'cover',
    })
    .toBuffer();

  const composed = await sharp(base)
    .composite([{ input: buildOverlaySvg(phrase) }])
    .jpeg({ quality: 85 })
    .toBuffer();

  const filename = `${randomUUID()}.jpg`;

  const originalPath = path.join(
    process.cwd(),
    'uploads',
    'original',
    filename,
  );

  const thumbPath = path.join(process.cwd(), 'uploads', 'thumb', filename);

  await sharp(composed).toFile(originalPath);

  await sharp(composed)
    .resize({ width: 300 })
    .jpeg({ quality: 70 })
    .toFile(thumbPath);

  return {
    filename,

    originalUrl: `http://localhost:3000/uploads/original/${filename}`,

    thumbUrl: `http://localhost:3000/uploads/thumb/${filename}`,
  };
}
