import { Injectable } from '@nestjs/common';

import { Cron } from '@nestjs/schedule';

import { ScraperService } from './scraper.service';

@Injectable()
export class ScraperScheduler {
  constructor(
    private scraperService: ScraperService,
  ) {}

  @Cron('0 */6 * * *')
  async handleScraping() {
    console.log(
      'Iniciando scraping automático...',
    );

    try {
      const result =
        await this.scraperService.scrapeAllCategories();

      console.log(
        'Scraping finalizado:',
        result,
      );
    } catch (error) {
      console.error(
        'Erro no scraping automático:',
        error,
      );
    }
  }
}