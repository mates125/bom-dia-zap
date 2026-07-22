import { Test, TestingModule } from '@nestjs/testing';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';

describe('CategoriesController', () => {
  let controller: CategoriesController;
  let categoriesService: { findAll: jest.Mock };

  beforeEach(async () => {
    categoriesService = {
      findAll: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CategoriesController],
      providers: [{ provide: CategoriesService, useValue: categoriesService }],
    }).compile();

    controller = module.get<CategoriesController>(CategoriesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('findAll', () => {
    it('delegates to categoriesService.findAll', async () => {
      const categories = [{ id: 1, name: 'Bom dia', slug: 'bom-dia' }];
      categoriesService.findAll.mockResolvedValue(categories);

      await expect(controller.findAll()).resolves.toBe(categories);
      expect(categoriesService.findAll).toHaveBeenCalledTimes(1);
    });
  });
});
