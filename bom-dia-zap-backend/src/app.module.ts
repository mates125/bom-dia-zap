import { CategoriesModule } from './categories/categories.module';
import { BrowserModule } from './browser/browser.module';
import { ServeStaticModule } from '@nestjs/serve-static';
import { ScraperModule } from './scraper/scraper.module';
import { ImagesModule } from './images/images.module';
import { PrismaModule } from './prisma/prisma.module';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { Module } from '@nestjs/common';
import { join } from 'path';

@Module({
  imports: [BrowserModule, ScraperModule, 
            CategoriesModule, ImagesModule, 
            PrismaModule, 
            ServeStaticModule.forRoot({
              rootPath: join(process.cwd(), 'uploads'),
              serveRoot: '/uploads',
            }),
            ScheduleModule.forRoot(),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}