import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface FindAllParams {
  category?: string;
  page: number;
  limit: number;
}

@Injectable()
export class ImagesService {
  constructor(private prisma: PrismaService) {}

  async findAll({ category, page, limit }: FindAllParams) {
    const skip = (page - 1) * limit;

    const images = await this.prisma.image.findMany({
      where: category
        ? {
            category: {
              slug: category,
            },
          }
        : undefined,

      include: {
        category: true,
      },

      orderBy: {
        createdAt: 'desc',
      },

      skip,
      take: limit,
    });

    const total = await this.prisma.image.count({
      where: category
        ? {
            category: {
              slug: category,
            },
          }
        : undefined,
    });

    return {
      data: images,

      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
