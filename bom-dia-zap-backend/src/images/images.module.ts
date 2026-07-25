import { Module } from '@nestjs/common';
import { ImagesController } from './images.controller';
import { ImagesService } from './images.service';
import { CollectionsModule } from '../collections/collections.module';

@Module({
  imports: [CollectionsModule],
  controllers: [ImagesController],
  providers: [ImagesService],
})
export class ImagesModule {}
