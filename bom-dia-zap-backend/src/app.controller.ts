import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { ContentService } from './content/content.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly contentService: ContentService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('generate')
  generate() {
    return this.contentService.generateForAllCategories();
  }
}
