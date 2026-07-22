import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { PexelsProvider } from './providers/pexels.provider';
import { composeImage } from '../utils/compose-image';
import { CATEGORY_SEARCH_QUERIES, PHRASE_BANK } from './phrase-bank';

const IMAGES_PER_RUN = 8;

function pickRandom<T>(items: T[]): T {
  return items[Math.floor(Math.random() * items.length)];
}

@Injectable()
export class ContentService {
  constructor(
    private prisma: PrismaService,
    private pexelsProvider: PexelsProvider,
  ) {}

  async generateForCategory(categorySlug: string) {
    const queries = CATEGORY_SEARCH_QUERIES[categorySlug];
    const phrases = PHRASE_BANK[categorySlug];

    if (!queries || !phrases) {
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

    const query = pickRandom(queries);
    const photos = await this.pexelsProvider.searchPhotos(query);

    let savedCount = 0;

    for (const photo of photos.slice(0, IMAGES_PER_RUN)) {
      const phrase = pickRandom(phrases);
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
        const composed = await composeImage(photo.downloadUrl, phrase);

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
      photosFound: photos.length,
      saved: savedCount,
    };
  }

  async generateForAllCategories() {
    const categories = Object.keys(PHRASE_BANK);

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
