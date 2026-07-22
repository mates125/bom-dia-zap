import { Injectable } from '@nestjs/common';
import { BrowserService } from '../../browser/browser.service';

export interface ScrapedImage {
  src: string;
  alt: string;
}

const MAX_HUB_PAGES = 3;

const NON_ARTICLE_PATHS = new Set([
  '/',
  '/contribuicao/',
  '/frases/',
  '/autores/',
  '/comunidade/',
  '/biografias/',
  '/login/',
  '/cadastro/',
  '/sobre/',
  '/contato/',
  '/anunciar/',
  '/termos-de-uso/',
  '/politica-de-privacidade/',
]);

@Injectable()
export class PensadorProvider {
  constructor(private browserService: BrowserService) {}

  /**
   * As páginas de categoria do Pensador são "hubs" que listam links para
   * artigos individuais (cada um com várias imagens prontas). Este método
   * percorre as páginas do hub e retorna as URLs únicas de artigos encontradas.
   */
  async discoverArticleUrls(hubUrl: string): Promise<string[]> {
    const browser = await this.browserService.getBrowser();
    const page = await browser.newPage();

    const hubOrigin = new URL(hubUrl).origin;
    const hubPathname = new URL(hubUrl).pathname;

    const discovered = new Set<string>();

    try {
      for (let currentPage = 1; currentPage <= MAX_HUB_PAGES; currentPage++) {
        const pageUrl = `${hubUrl}${currentPage}/`;

        await page.goto(pageUrl, {
          waitUntil: 'domcontentloaded',
        });

        const paths: string[] = await page.$$eval(
          'a[href]',
          (elements, origin) => {
            return elements
              .map((el) => (el as HTMLAnchorElement).href)
              .filter((href) => href.startsWith(origin));
          },
          hubOrigin,
        );

        for (const href of paths) {
          const url = new URL(href, hubOrigin);

          if (url.origin !== hubOrigin) continue;
          if (url.pathname === hubPathname) continue;
          if (url.pathname.endsWith('.php')) continue;
          if (NON_ARTICLE_PATHS.has(url.pathname)) continue;

          const isSingleArticleSegment = /^\/[a-z0-9_]+\/$/.test(url.pathname);

          if (!isSingleArticleSegment) continue;

          discovered.add(`${url.origin}${url.pathname}`);
        }
      }
    } finally {
      await page.close();
    }

    return Array.from(discovered);
  }

  /**
   * Extrai as imagens prontas (frase + fundo) de um artigo específico.
   * O seletor `.content-img` é o container real usado pelo Pensador para
   * essas imagens; o filtro antigo por width/height falhava porque essas
   * imagens usam lazy-load e só ganham dimensões reais quando entram na
   * viewport.
   */
  async scrapeArticle(articleUrl: string): Promise<ScrapedImage[]> {
    const browser = await this.browserService.getBrowser();
    const page = await browser.newPage();

    try {
      await page.goto(articleUrl, {
        waitUntil: 'domcontentloaded',
      });

      return await page.$$eval('.content-img img', (elements) => {
        return elements
          .map((img) => ({
            src: img.getAttribute('data-src') || (img as HTMLImageElement).src,
            alt: (img as HTMLImageElement).alt,
          }))
          .filter((image) => image.src?.startsWith('http'));
      });
    } finally {
      await page.close();
    }
  }
}
