import { Test, TestingModule } from '@nestjs/testing';
import { CategoriesService } from './categories.service';
import { PrismaService } from '../prisma/prisma.service';

describe('CategoriesService', () => {
  let service: CategoriesService;
  let prisma: { category: { findMany: jest.Mock } };

  beforeEach(async () => {
    prisma = {
      category: {
        findMany: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoriesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<CategoriesService>(CategoriesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('calls prisma.category.findMany and returns its result', async () => {
      const categories = [{ id: 1, name: 'Bom dia', slug: 'bom-dia' }];
      prisma.category.findMany.mockResolvedValue(categories);

      await expect(service.findAll()).resolves.toBe(categories);
      expect(prisma.category.findMany).toHaveBeenCalledTimes(1);
    });
  });
});
