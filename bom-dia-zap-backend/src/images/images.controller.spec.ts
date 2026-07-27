import { Test, TestingModule } from '@nestjs/testing';
import { ImagesController } from './images.controller';
import { ImagesService } from './images.service';
import { CollectionsService } from '../collections/collections.service';

describe('ImagesController', () => {
  let controller: ImagesController;
  let imagesService: { findAll: jest.Mock };
  let collectionsService: {
    likeImage: jest.Mock;
    unlikeImage: jest.Mock;
    isImageLiked: jest.Mock;
  };

  beforeEach(async () => {
    imagesService = {
      findAll: jest.fn(),
    };

    collectionsService = {
      likeImage: jest.fn(),
      unlikeImage: jest.fn(),
      isImageLiked: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ImagesController],
      providers: [
        { provide: ImagesService, useValue: imagesService },
        { provide: CollectionsService, useValue: collectionsService },
      ],
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

      await expect(
        controller.findAll('bom-dia', '3', '5'),
      ).resolves.toBe(response);
      expect(imagesService.findAll).toHaveBeenCalledWith({
        category: 'bom-dia',
        page: 3,
        limit: 5,
        withSourceUrl: false,
      });
    });

    it('parses withSourceUrl=true', async () => {
      imagesService.findAll.mockResolvedValue({ data: [], meta: {} });

      await controller.findAll(undefined, '1', '20', 'true');

      expect(imagesService.findAll).toHaveBeenCalledWith({
        category: undefined,
        page: 1,
        limit: 20,
        withSourceUrl: true,
      });
    });

    it('defaults page and limit when not provided', async () => {
      imagesService.findAll.mockResolvedValue({ data: [], meta: {} });

      await controller.findAll();

      expect(imagesService.findAll).toHaveBeenCalledWith({
        category: undefined,
        page: 1,
        limit: 20,
        withSourceUrl: false,
      });
    });
  });

  describe('like / unlike', () => {
    it('delegates like to collectionsService.likeImage', async () => {
      collectionsService.likeImage.mockResolvedValue(undefined);

      await controller.like({ userId: 7 }, 42);

      expect(collectionsService.likeImage).toHaveBeenCalledWith(7, 42);
    });

    it('delegates unlike to collectionsService.unlikeImage', async () => {
      collectionsService.unlikeImage.mockResolvedValue(undefined);

      await controller.unlike({ userId: 7 }, 42);

      expect(collectionsService.unlikeImage).toHaveBeenCalledWith(7, 42);
    });

    it('delegates likeStatus to collectionsService.isImageLiked', async () => {
      collectionsService.isImageLiked.mockResolvedValue({ isLiked: true });

      await expect(
        controller.likeStatus({ userId: 7 }, 42),
      ).resolves.toEqual({ isLiked: true });
      expect(collectionsService.isImageLiked).toHaveBeenCalledWith(7, 42);
    });
  });
});
