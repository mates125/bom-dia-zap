import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

interface FindAllParams {
  category?: string;
  page: number;
  limit: number;
  withSourceUrl?: boolean;
}

@Injectable()
export class ImagesService {
  constructor(private prisma: PrismaService) {}

  async findAll({ category, page, limit, withSourceUrl }: FindAllParams) {
    const skip = (page - 1) * limit;

    const where: Prisma.ImageWhereInput = {
      ...(category ? { category: { slug: category } } : {}),
      // Editor premium: só faz sentido oferecer fundos 100% sem texto —
      // nunca a versão já composta como reserva.
      ...(withSourceUrl ? { sourceUrl: { not: null } } : {}),
    };

    const images = await this.prisma.image.findMany({
      where,
      include: {
        category: true,
      },

      orderBy: {
        createdAt: 'desc',
      },

      skip,
      take: limit,
    });

    const total = await this.prisma.image.count({ where });

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
