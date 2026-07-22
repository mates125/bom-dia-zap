import { Test, TestingModule } from '@nestjs/testing';
import { ImagesService } from './images.service';
import { PrismaService } from '../prisma/prisma.service';

describe('ImagesService', () => {
  let service: ImagesService;
  let prisma: {
    image: { findMany: jest.Mock; count: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      image: {
        findMany: jest.fn(),
        count: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [ImagesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<ImagesService>(ImagesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('queries prisma with pagination and returns data with meta', async () => {
      const images = [{ id: 1, title: 'foo' }];
      prisma.image.findMany.mockResolvedValue(images);
      prisma.image.count.mockResolvedValue(42);

      const result = await service.findAll({ page: 2, limit: 10 });

      expect(prisma.image.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 10, take: 10 }),
      );
      expect(result).toEqual({
        data: images,
        meta: { total: 42, page: 2, limit: 10, totalPages: 5 },
      });
    });

    it('filters by category slug when category is provided', async () => {
      prisma.image.findMany.mockResolvedValue([]);
      prisma.image.count.mockResolvedValue(0);

      await service.findAll({ category: 'bom-dia', page: 1, limit: 20 });

      expect(prisma.image.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { category: { slug: 'bom-dia' } },
        }),
      );
    });
  });
});
