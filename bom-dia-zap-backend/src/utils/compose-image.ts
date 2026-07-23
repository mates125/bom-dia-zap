import axios from 'axios';
import { randomUUID } from 'crypto';
import * as path from 'path';
import sharp from 'sharp';

const CANVAS_WIDTH = 1080;
const CANVAS_HEIGHT = 1350;
const MAX_CHARS_PER_LINE = 24;
const HEADER_FONT_SIZE = 96;
const PHRASE_FONT_SIZE = 50;
const BRAND = 'Bom Dia Zap';

// Em produção, instale essas fontes no sistema (ex.: COPY + fc-cache num
// Dockerfile) para a primeira opção de cada pilha ser usada. Sem isso, o
// render cai graciosamente para as fontes seguintes da lista.
const HEADER_FONT_STACK =
  "'Great Vibes', 'Segoe Script', 'Brush Script MT', cursive";
const BODY_FONT_STACK = "'Poppins', 'Segoe UI', Arial, sans-serif";

export interface ComposeImageOptions {
  photoUrl: string;
  phrase: string;
  header: string;
  accentColor: string;
}

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

function buildOverlaySvg({
  phrase,
  header,
  accentColor,
}: Omit<ComposeImageOptions, 'photoUrl'>): Buffer {
  const phraseLines = wrapText(phrase, MAX_CHARS_PER_LINE);
  const phraseLineHeight = PHRASE_FONT_SIZE * 1.35;
  const headerLineHeight = HEADER_FONT_SIZE * 1.05;
  const gapBetween = 30;
  const bottomMargin = 190;

  const phraseBlockHeight = phraseLines.length * phraseLineHeight;
  const totalBlockHeight = headerLineHeight + gapBetween + phraseBlockHeight;

  const blockBottom = CANVAS_HEIGHT - bottomMargin;
  const blockTop = blockBottom - totalBlockHeight;

  // A área escura acompanha o tamanho real do texto (em vez de uma altura
  // fixa) para que frases mais longas — vindas da raspagem, com tamanho
  // variável — nunca fiquem sem contraste suficiente pra leitura.
  const scrimTop = Math.min(CANVAS_HEIGHT * 0.4, blockTop - 60);

  const headerY = blockTop + HEADER_FONT_SIZE * 0.85;
  const phraseStartY = headerY + gapBetween + PHRASE_FONT_SIZE * 0.85;
  const ruleY = headerY + 26;

  const phraseTspans = phraseLines
    .map(
      (line, index) =>
        `<tspan x="${CANVAS_WIDTH / 2}" dy="${index === 0 ? 0 : phraseLineHeight}">${escapeXml(line)}</tspan>`,
    )
    .join('');

  const escapedHeader = escapeXml(header);

  const svg = `
    <svg width="${CANVAS_WIDTH}" height="${CANVAS_HEIGHT}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="scrim" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#000000" stop-opacity="0"/>
          <stop offset="100%" stop-color="#000000" stop-opacity="0.82"/>
        </linearGradient>
      </defs>

      <rect x="0" y="${scrimTop}" width="${CANVAS_WIDTH}" height="${CANVAS_HEIGHT - scrimTop}" fill="url(#scrim)"/>

      <!-- cabeçalho cursivo com sombra sutil -->
      <text x="${CANVAS_WIDTH / 2 + 3}" y="${headerY + 3}" font-family="${HEADER_FONT_STACK}" font-size="${HEADER_FONT_SIZE}" fill="#000000" fill-opacity="0.35" text-anchor="middle">${escapedHeader}</text>
      <text x="${CANVAS_WIDTH / 2}" y="${headerY}" font-family="${HEADER_FONT_STACK}" font-size="${HEADER_FONT_SIZE}" fill="${accentColor}" text-anchor="middle">${escapedHeader}</text>

      <rect x="${CANVAS_WIDTH / 2 - 34}" y="${ruleY}" width="68" height="5" rx="2.5" fill="${accentColor}"/>

      <!-- frase em negrito com sombra sutil -->
      <text x="${CANVAS_WIDTH / 2 + 2}" y="${phraseStartY + 2}" font-family="${BODY_FONT_STACK}" font-weight="700" font-size="${PHRASE_FONT_SIZE}" fill="#000000" fill-opacity="0.35" text-anchor="middle">${phraseTspans}</text>
      <text x="${CANVAS_WIDTH / 2}" y="${phraseStartY}" font-family="${BODY_FONT_STACK}" font-weight="700" font-size="${PHRASE_FONT_SIZE}" fill="#ffffff" text-anchor="middle">${phraseTspans}</text>

      <!-- selo de marca -->
      <rect x="${CANVAS_WIDTH / 2 - 100}" y="${CANVAS_HEIGHT - 96}" width="200" height="44" rx="22" fill="#ffffff" fill-opacity="0.14"/>
      <text x="${CANVAS_WIDTH / 2}" y="${CANVAS_HEIGHT - 66}" font-family="${BODY_FONT_STACK}" font-weight="700" font-size="24" fill="#ffffff" text-anchor="middle">${escapeXml(BRAND)}</text>
    </svg>
  `;

  return Buffer.from(svg);
}

/**
 * Baixa uma foto de banco de imagens e compõe a frase por cima, gerando o
 * cartão final (original + thumbnail) que o app vai servir.
 */
export async function composeImage(
  options: ComposeImageOptions,
): Promise<{ filename: string; originalUrl: string; thumbUrl: string }> {
  const response = await axios({
    url: options.photoUrl,
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
    .composite([{ input: buildOverlaySvg(options) }])
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
