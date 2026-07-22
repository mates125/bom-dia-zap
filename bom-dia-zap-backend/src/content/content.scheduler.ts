import { Injectable } from '@nestjs/common';

import { Cron } from '@nestjs/schedule';

import { ContentService } from './content.service';

@Injectable()
export class ContentScheduler {
  constructor(private contentService: ContentService) {}

  @Cron('0 */6 * * *')
  async handleGeneration() {
    console.log('Iniciando geração automática de conteúdo...');

    try {
      const result = await this.contentService.generateForAllCategories();

      console.log('Geração finalizada:', result);
    } catch (error) {
      console.error('Erro na geração automática:', error);
    }
  }
}
