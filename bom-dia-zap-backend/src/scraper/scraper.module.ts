import { PensadorProvider } from './providers/pensador.provider';
import { ScraperScheduler } from './scraper.scheduler';
import { ScraperService } from './scraper.service';
import { Module } from '@nestjs/common';

@Module({
  providers: [
    ScraperService,
    PensadorProvider,
    ScraperScheduler,
  ],

  exports: [ScraperService],
})
export class ScraperModule {}