import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { PensadorProvider } from './providers/pensador.provider';
import { downloadImage } from '../utils/download-image';

const MAX_NEW_ARTICLES_PER_RUN = 20;

interface CategoryConfig {
  hubUrl: string;
  // As páginas de categoria do Pensador se linkam entre si (ex: o hub de
  // "boa tarde" lista artigos de "bom dia"). Esse filtro evita que uma
  // categoria acabe importando imagens de outro tema.
  keywords: string[];
}

const CATEGORIES: Record<string, CategoryConfig> = {
  'bom-dia': {
    hubUrl: 'https://www.pensador.com/mensagens_de_bom_dia/',
    keywords: ['bom_dia'],
  },
  'boa-tarde': {
    hubUrl: 'https://www.pensador.com/boa_tarde/',
    keywords: ['tarde'],
  },
  'boa-noite': {
    hubUrl: 'https://www.pensador.com/mensagens_de_boa_noite/',
    keywords: ['noite'],
  },
  motivacional: {
    hubUrl: 'https://www.pensador.com/frases_motivacionais/',
    keywords: ['motiva'],
  },
};

@Injectable()
export class ScraperService {
  constructor(
    private prisma: PrismaService,
    private pensadorProvider: PensadorProvider,
  ) {}

  async scrapeCategory(categorySlug: string) {
    const config = CATEGORIES[categorySlug];

    if (!config) {
      throw new Error(
        `Nenhuma URL de scraping configurada para a categoria ${categorySlug}`,
      );
    }

    const { hubUrl, keywords } = config;

    const category = await this.prisma.category.findFirst({
      where: { slug: categorySlug },
    });

    if (!category) {
      throw new Error(`Categoria ${categorySlug} não encontrada`);
    }

    const discoveredUrls =
      await this.pensadorProvider.discoverArticleUrls(hubUrl);

    const articleUrls = discoveredUrls.filter((url) =>
      keywords.some((keyword) => url.includes(keyword)),
    );

    const alreadyScraped = await this.prisma.scrapedArticle.findMany({
      where: {
        categoryId: category.id,
        url: { in: articleUrls },
      },
      select: { url: true },
    });

    const alreadyScrapedUrls = new Set(
      alreadyScraped.map((article) => article.url),
    );

    const newArticleUrls = articleUrls
      .filter((url) => !alreadyScrapedUrls.has(url))
      .slice(0, MAX_NEW_ARTICLES_PER_RUN);

    const images: { src: string; alt: string }[] = [];

    for (const articleUrl of newArticleUrls) {
      try {
        const articleImages =
          await this.pensadorProvider.scrapeArticle(articleUrl);

        images.push(...articleImages);
      } catch (error) {
        console.error('Erro ao raspar artigo:', articleUrl, error);
      } finally {
        await this.prisma.scrapedArticle.create({
          data: {
            url: articleUrl,
            categoryId: category.id,
          },
        });
      }
    }

    const hashes = images.map((image) =>
      createHash('sha256').update(image.src).digest('hex'),
    );

    const existingImages = await this.prisma.image.findMany({
      where: {
        hash: { in: hashes },
      },
      select: { hash: true },
    });

    const processedHashes = new Set(existingImages.map((image) => image.hash));

    let savedCount = 0;

    for (const image of images) {
      const hash = createHash('sha256').update(image.src).digest('hex');

      if (processedHashes.has(hash)) {
        continue;
      }

      processedHashes.add(hash);

      try {
        const downloadedImage = await downloadImage(image.src);

        await this.prisma.image.create({
          data: {
            title: image.alt || category.name,
            imageUrl: downloadedImage.originalUrl,
            thumbnailUrl: downloadedImage.thumbUrl,
            sourceUrl: hubUrl,
            hash,
            categoryId: category.id,
          },
        });

        savedCount++;
      } catch (error) {
        console.error('Erro ao baixar imagem:', image.src, error);
      }
    }

    return {
      articlesDiscovered: articleUrls.length,
      articlesProcessed: newArticleUrls.length,
      imagesFound: images.length,
      saved: savedCount,
    };
  }

  async scrapeAllCategories() {
    const categories = Object.keys(CATEGORIES);

    const results = await Promise.all(
      categories.map(async (categorySlug) => {
        console.log(`Iniciando categoria ${categorySlug}`);

        const result = await this.scrapeCategory(categorySlug);

        return {
          category: categorySlug,
          ...result,
        };
      }),
    );

    return results;
  }
}
