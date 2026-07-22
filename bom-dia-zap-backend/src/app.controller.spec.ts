import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ScraperService } from './scraper/scraper.service';

describe('AppController', () => {
  let appController: AppController;
  let scraperService: { scrapeAllCategories: jest.Mock };

  beforeEach(async () => {
    scraperService = {
      scrapeAllCategories: jest.fn(),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        { provide: ScraperService, useValue: scraperService },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(appController.getHello()).toBe('Hello World!');
    });
  });

  describe('scrape', () => {
    it('delegates to scraperService.scrapeAllCategories', async () => {
      const result = [{ category: 'bom-dia', saved: 3 }];
      scraperService.scrapeAllCategories.mockResolvedValue(result);

      await expect(appController.scrape()).resolves.toBe(result);
      expect(scraperService.scrapeAllCategories).toHaveBeenCalledTimes(1);
    });
  });
});
