import { Injectable } from '@nestjs/common';
import axios from 'axios';
import * as cheerio from 'cheerio';

const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

// Cada categoria mapeia pra um artigo real do site, validado manualmente
// (sem proteção anti-bot — HTML puro, sem precisar de navegador).
const CATEGORY_URLS: Record<string, string> = {
  'bom-dia': 'https://www.mensagenscomamor.com/frases-bom-dia',
  'boa-tarde': 'https://www.mensagenscomamor.com/frases-curtas-boa-tarde',
  'boa-noite': 'https://www.mensagenscomamor.com/frases-boa-noite',
  cristao: 'https://www.mensagenscomamor.com/frases-cristas',
  motivacional: 'https://www.mensagenscomamor.com/frases-motivacionais',
  amor: 'https://www.mensagenscomamor.com/frases-de-amor',
};

const MIN_LENGTH = 20;
// Frases muito longas (várias frases coladas) não cabem direito no cartão
// mesmo com a área escura dinâmica — melhor deixar de fora na raspagem.
const MAX_LENGTH = 150;

@Injectable()
export class MensagensComAmorProvider {
  readonly sourceName = 'mensagenscomamor.com';

  async scrapePhrases(categorySlug: string): Promise<string[]> {
    const url = CATEGORY_URLS[categorySlug];

    if (!url) {
      return [];
    }

    const response = await axios.get<string>(url, {
      headers: { 'User-Agent': USER_AGENT },
    });

    const $ = cheerio.load(response.data);
    const phrases: string[] = [];

    $('p').each((_, element) => {
      const text = $(element).text().replace(/\s+/g, ' ').trim();

      const endsLikeASentence = /["'.!?]$/.test(text);
      const looksLikeNavList = (text.match(/Frases /g) ?? []).length > 1;

      if (
        text.length >= MIN_LENGTH &&
        text.length <= MAX_LENGTH &&
        endsLikeASentence &&
        !looksLikeNavList
      ) {
        phrases.push(text);
      }
    });

    return phrases;
  }
}
