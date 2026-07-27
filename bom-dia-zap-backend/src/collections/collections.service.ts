import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const FREE_TIER_CUSTOM_COLLECTION_LIMIT = 1;

@Injectable()
export class CollectionsService {
  constructor(private prisma: PrismaService) {}

  async listForUser(userId: number) {
    const collections = await this.prisma.collection.findMany({
      where: { userId },
      include: { _count: { select: { images: true } } },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'asc' }],
    });

    return collections.map((collection) => ({
      id: collection.id,
      name: collection.name,
      isDefault: collection.isDefault,
      imageCount: collection._count.images,
    }));
  }

  async create(userId: number, name: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });

    if (!user.isPremium) {
      const customCollectionCount = await this.prisma.collection.count({
        where: { userId, isDefault: false },
      });

      if (customCollectionCount >= FREE_TIER_CUSTOM_COLLECTION_LIMIT) {
        throw new ForbiddenException({
          code: 'COLLECTION_LIMIT_REACHED',
          message:
            'Contas gratuitas podem ter só uma coleção própria. Vire premium pra criar mais.',
        });
      }
    }

    try {
      return await this.prisma.collection.create({
        data: { userId, name },
      });
    } catch {
      throw new ConflictException('Você já tem uma coleção com esse nome');
    }
  }

  async delete(userId: number, collectionId: number) {
    const collection = await this.findOwned(userId, collectionId);

    if (collection.isDefault) {
      throw new ForbiddenException('Não é possível apagar a coleção Curtidas');
    }

    await this.prisma.collection.delete({ where: { id: collectionId } });
  }

  async addImage(userId: number, collectionId: number, imageId: number) {
    await this.findOwned(userId, collectionId);

    await this.prisma.collectionImage.upsert({
      where: { collectionId_imageId: { collectionId, imageId } },
      update: {},
      create: { collectionId, imageId },
    });
  }

  async removeImage(userId: number, collectionId: number, imageId: number) {
    await this.findOwned(userId, collectionId);

    await this.prisma.collectionImage.deleteMany({
      where: { collectionId, imageId },
    });
  }

  async listImages(
    userId: number,
    collectionId: number,
    page: number,
    limit: number,
  ) {
    await this.findOwned(userId, collectionId);

    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.prisma.collectionImage.findMany({
        where: { collectionId },
        include: { image: { include: { category: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.collectionImage.count({ where: { collectionId } }),
    ]);

    return {
      data: items.map((item) => item.image),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async likeImage(userId: number, imageId: number) {
    const liked = await this.ensureLikedCollection(userId);
    await this.addImage(userId, liked.id, imageId);
  }

  async isImageLiked(userId: number, imageId: number) {
    const liked = await this.ensureLikedCollection(userId);
    const entry = await this.prisma.collectionImage.findUnique({
      where: { collectionId_imageId: { collectionId: liked.id, imageId } },
    });

    return { isLiked: entry !== null };
  }

  async unlikeImage(userId: number, imageId: number) {
    const liked = await this.ensureLikedCollection(userId);
    await this.removeImage(userId, liked.id, imageId);
  }

  private async ensureLikedCollection(userId: number) {
    return this.prisma.collection.findFirstOrThrow({
      where: { userId, isDefault: true },
    });
  }

  private async findOwned(userId: number, collectionId: number) {
    const collection = await this.prisma.collection.findUnique({
      where: { id: collectionId },
    });

    if (!collection || collection.userId !== userId) {
      throw new NotFoundException('Coleção não encontrada');
    }

    return collection;
  }
}
