import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { PexelsProvider } from './providers/pexels.provider';
import { MensagensComAmorProvider } from './providers/mensagens-com-amor.provider';
import { composeImage } from '../utils/compose-image';
import { CATEGORY_SEARCH_QUERIES, CATEGORY_STYLES } from './phrase-bank';

const IMAGES_PER_RUN = 8;

function pickRandom<T>(items: T[]): T {
  return items[Math.floor(Math.random() * items.length)];
}

@Injectable()
export class ContentService {
  constructor(
    private prisma: PrismaService,
    private pexelsProvider: PexelsProvider,
    private mensagensComAmorProvider: MensagensComAmorProvider,
  ) {}

  /**
   * Raspa frases novas da fonte externa e adiciona ao pool da categoria no
   * banco (deduplicando por texto). Não falha a geração se a fonte externa
   * estiver fora do ar — o pool já tem as frases curadas do seed.
   */
  private async refreshPhrasePool(categorySlug: string, categoryId: number) {
    try {
      const scraped =
        await this.mensagensComAmorProvider.scrapePhrases(categorySlug);

      if (scraped.length === 0) {
        return;
      }

      await this.prisma.phrase.createMany({
        data: scraped.map((text) => ({
          text,
          source: this.mensagensComAmorProvider.sourceName,
          categoryId,
        })),
        skipDuplicates: true,
      });
    } catch (error) {
      console.error(`Erro ao raspar frases para ${categorySlug}:`, error);
    }
  }

  async generateForCategory(categorySlug: string) {
    const queries = CATEGORY_SEARCH_QUERIES[categorySlug];
    const style = CATEGORY_STYLES[categorySlug];

    if (!queries || !style) {
      throw new Error(
        `Categoria ${categorySlug} não configurada para geração de conteúdo`,
      );
    }

    const category = await this.prisma.category.findFirst({
      where: { slug: categorySlug },
    });

    if (!category) {
      throw new Error(`Categoria ${categorySlug} não encontrada`);
    }

    await this.refreshPhrasePool(categorySlug, category.id);

    const phrases = await this.prisma.phrase.findMany({
      where: { categoryId: category.id },
      select: { text: true },
    });

    if (phrases.length === 0) {
      throw new Error(
        `Nenhuma frase disponível para a categoria ${categorySlug}`,
      );
    }

    const query = pickRandom(queries);
    const photos = await this.pexelsProvider.searchPhotos(query);

    let savedCount = 0;

    for (const photo of photos.slice(0, IMAGES_PER_RUN)) {
      const phrase = pickRandom(phrases).text;
      const hash = createHash('sha256')
        .update(`${photo.id}-${phrase}`)
        .digest('hex');

      const existing = await this.prisma.image.findUnique({
        where: { hash },
      });

      if (existing) {
        continue;
      }

      try {
        const composed = await composeImage({
          photoUrl: photo.downloadUrl,
          phrase,
          header: style.header,
          accentColor: style.color,
        });

        await this.prisma.image.create({
          data: {
            title: phrase,
            imageUrl: composed.originalUrl,
            thumbnailUrl: composed.thumbUrl,
            sourceUrl: photo.photoUrl,
            photographer: photo.photographer,
            hash,
            categoryId: category.id,
          },
        });

        savedCount++;
      } catch (error) {
        console.error('Erro ao compor imagem:', photo.id, error);
      }
    }

    return {
      query,
      phrasePoolSize: phrases.length,
      photosFound: photos.length,
      saved: savedCount,
    };
  }

  async generateForAllCategories() {
    const categories = Object.keys(CATEGORY_STYLES);

    const results = await Promise.all(
      categories.map(async (categorySlug) => {
        console.log(`Gerando conteúdo para ${categorySlug}`);

        const result = await this.generateForCategory(categorySlug);

        return {
          category: categorySlug,
          ...result,
        };
      }),
    );

    return results;
  }
}
