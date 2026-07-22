import { PexelsProvider } from './providers/pexels.provider';
import { ContentScheduler } from './content.scheduler';
import { ContentService } from './content.service';
import { Module } from '@nestjs/common';

@Module({
  providers: [ContentService, PexelsProvider, ContentScheduler],

  exports: [ContentService],
})
export class ContentModule {}
