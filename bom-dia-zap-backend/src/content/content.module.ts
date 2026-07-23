import { MensagensComAmorProvider } from './providers/mensagens-com-amor.provider';
import { PexelsProvider } from './providers/pexels.provider';
import { ContentScheduler } from './content.scheduler';
import { ContentService } from './content.service';
import { Module } from '@nestjs/common';

@Module({
  providers: [
    ContentService,
    PexelsProvider,
    MensagensComAmorProvider,
    ContentScheduler,
  ],

  exports: [ContentService],
})
export class ContentModule {}
