import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { PensadorProvider } from './providers/pensador.provider';
import { downloadImage } from '../utils/download-image';

const CATEGORY_URLS = {
  'bom-dia':
    'https://www.pensador.com/mensagens_de_bom_dia/',

  'boa-tarde':
    'https://www.pensador.com/mensagens_de_boa_tarde/',

  'boa-noite':
    'https://www.pensador.com/mensagens_de_boa_noite/',

  'cristao':
    'https://www.pensador.com/frases_cristas/',

  'motivacional':
    'https://www.pensador.com/frases_motivacionais/',

  'amor':
    'https://www.pensador.com/frases_de_amor/',
};

@Injectable()
export class ScraperService {

  constructor(
    private prisma: PrismaService,
    private pensadorProvider: PensadorProvider,
  ) {}

  async scrapeCategory(categorySlug: string,) {
    const images =
      await this.pensadorProvider.scrapeCategory(
        CATEGORY_URLS[categorySlug],
      );

    const hashes = images.map((image) =>
      createHash('sha256')
      .update(image.src)
      .digest('hex'),
    );

    const existingImages =
      await this.prisma.image.findMany({
      where: {
        hash: {
          in: hashes,
        },
      },

      select: {
        hash: true,
      },
    });

    const existingHashes =
      new Set(
        existingImages.map(
          (image) => image.hash,
        ),
      );

    const processedHashes =
      new Set(existingHashes);

    const category = await this.prisma.category.findFirst({
      where: {
        slug: categorySlug,
      },
    });

    if (!category) {
      throw new Error(
        'Categoria bom-dia não encontrada',
      );
    }

    let savedCount = 0;

    for (const image of images) {
      const hash = createHash('sha256')
        .update(image.src)
        .digest('hex');

      if (processedHashes.has(hash)) {
        continue;
      }

      try {
            const downloadedImage =
              await downloadImage(image.src);

            await this.prisma.image.create({
              data: {
                title: image.alt || 'Bom dia',

                imageUrl: 
                  downloadedImage.originalUrl,

                thumbnailUrl: 
                  downloadedImage.thumbUrl,

                sourceUrl:
                  'https://www.pensador.com/mensagens_de_bom_dia/',

                hash,

                categoryId: category.id,
              },
            });

            savedCount++;
            processedHashes.add(hash);
          } catch (error) {
            console.error(
              'Erro ao baixar imagem:',
              image.src,
              error,
            );
          }
    }

    return {
      totalFound: images.length,
      saved: savedCount,
    };
  }

  async scrapeAllCategories() {
  const categories =
    Object.keys(CATEGORY_URLS);

  const results =
    await Promise.all(
      categories.map(
        async (categorySlug) => {
          console.log(
            `Iniciando categoria ${categorySlug}`,
          );

          const result =
            await this.scrapeCategory(
              categorySlug,
            );

          return {
            category: categorySlug,
            ...result,
          };
        },
      ),
    );

  return results;
}
}