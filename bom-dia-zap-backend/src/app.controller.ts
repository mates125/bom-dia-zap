import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { ScraperService } from './scraper/scraper.service';

@Controller()
  export class AppController {
    constructor(
    private readonly appService: AppService,
    private readonly scraperService: ScraperService,
  ) {}  

  @Get()
    getHello(): string {
      return this.appService.getHello();
    }

  @Get('scrape')
    scrape() {
      return this.scraperService
        .scrapeAllCategories();
    }
}
