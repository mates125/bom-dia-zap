import {
  Controller,
  Get,
  Query,
} from '@nestjs/common';

import { ImagesService } from './images.service';

@Controller('images')
export class ImagesController {
  constructor(
    private readonly imagesService: ImagesService,
  ) {}

  @Get()
  findAll(
    @Query('category') category?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    return this.imagesService.findAll({
      category,
      page: Number(page),
      limit: Number(limit),
    });
  }
}