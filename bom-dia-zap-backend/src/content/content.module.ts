import { MensagensComAmorProvider } from './providers/mensagens-com-amor.provider';
import { FrasesDoBemProvider } from './providers/frases-do-bem.provider';
import { PexelsProvider } from './providers/pexels.provider';
import { ContentScheduler } from './content.scheduler';
import { ContentService } from './content.service';
import { ContentController } from './content.controller';
import { Module } from '@nestjs/common';

@Module({
  controllers: [ContentController],

  providers: [
    ContentService,
    PexelsProvider,
    MensagensComAmorProvider,
    FrasesDoBemProvider,
    ContentScheduler,
  ],

  exports: [ContentService],
})
export class ContentModule {}
