import { Test, TestingModule } from '@nestjs/testing';
import { ImagesController } from './images.controller';
import { ImagesService } from './images.service';

describe('ImagesController', () => {
  let controller: ImagesController;
  let imagesService: { findAll: jest.Mock };

  beforeEach(async () => {
    imagesService = {
      findAll: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ImagesController],
      providers: [{ provide: ImagesService, useValue: imagesService }],
    }).compile();

    controller = module.get<ImagesController>(ImagesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('findAll', () => {
    it('parses query params and delegates to imagesService.findAll', async () => {
      const response = {
        data: [],
        meta: { total: 0, page: 3, limit: 5, totalPages: 0 },
      };
      imagesService.findAll.mockResolvedValue(response);

      await expect(controller.findAll('bom-dia', '3', '5')).resolves.toBe(
        response,
      );
      expect(imagesService.findAll).toHaveBeenCalledWith({
        category: 'bom-dia',
        page: 3,
        limit: 5,
      });
    });

    it('defaults page and limit when not provided', async () => {
      imagesService.findAll.mockResolvedValue({ data: [], meta: {} });

      await controller.findAll();

      expect(imagesService.findAll).toHaveBeenCalledWith({
        category: undefined,
        page: 1,
        limit: 20,
      });
    });
  });
});
