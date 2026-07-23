import { Injectable } from '@nestjs/common';
import axios from 'axios';
import * as cheerio from 'cheerio';

const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

// Validado manualmente. Esse site não tem uma página própria de "boa
// tarde" — a categoria fica sem contribuição desse provider, o que é
// normal: nem toda fonte cobre todas as categorias.
const CATEGORY_URLS: Record<string, string> = {
  'bom-dia': 'https://www.frasesdobem.com.br/frases-de-bom-dia',
  'boa-noite': 'https://www.frasesdobem.com.br/frases-de-boa-noite-abencoada',
  cristao: 'https://www.frasesdobem.com.br/frases-de-deus',
  motivacional: 'https://www.frasesdobem.com.br/frases-motivacionais',
  amor: 'https://www.frasesdobem.com.br/frases-de-amor',
};

const MIN_LENGTH = 25;
const MAX_LENGTH = 150;

@Injectable()
export class FrasesDoBemProvider {
  readonly sourceName = 'frasesdobem.com.br';

  async scrapePhrases(categorySlug: string): Promise<string[]> {
    const url = CATEGORY_URLS[categorySlug];

    if (!url) {
      return [];
    }

    const response = await axios.get<string>(url, {
      headers: { 'User-Agent': USER_AGENT },
    });

    const $ = cheerio.load(response.data);
    const phrases = new Set<string>();

    // As frases ficam em elementos "folha" (sem filhos) dentro de cards —
    // não há uma classe estável pra mirar, então varremos os tipos comuns
    // e filtramos pelo formato (tamanho + termina como frase).
    $('li, blockquote, span, div').each((_, element) => {
      if ($(element).children().length > 0) {
        return;
      }

      const text = $(element).text().replace(/\s+/g, ' ').trim();
      const endsLikeASentence = /["'.!?]$/.test(text);

      if (
        text.length >= MIN_LENGTH &&
        text.length <= MAX_LENGTH &&
        endsLikeASentence
      ) {
        phrases.add(text);
      }
    });

    return Array.from(phrases);
  }
}
