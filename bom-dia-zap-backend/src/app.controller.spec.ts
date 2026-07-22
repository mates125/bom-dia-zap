import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ContentService } from './content/content.service';

describe('AppController', () => {
  let appController: AppController;
  let contentService: { generateForAllCategories: jest.Mock };

  beforeEach(async () => {
    contentService = {
      generateForAllCategories: jest.fn(),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        { provide: ContentService, useValue: contentService },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(appController.getHello()).toBe('Hello World!');
    });
  });

  describe('generate', () => {
    it('delegates to contentService.generateForAllCategories', async () => {
      const result = [{ category: 'bom-dia', saved: 3 }];
      contentService.generateForAllCategories.mockResolvedValue(result);

      await expect(appController.generate()).resolves.toBe(result);
      expect(contentService.generateForAllCategories).toHaveBeenCalledTimes(1);
    });
  });
});
