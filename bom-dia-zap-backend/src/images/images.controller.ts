import {
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { ImagesService } from './images.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/current-user.decorator';
import { CollectionsService } from '../collections/collections.service';

@Controller('images')
export class ImagesController {
  constructor(
    private readonly imagesService: ImagesService,
    private readonly collectionsService: CollectionsService,
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

  @UseGuards(JwtAuthGuard)
  @Get(':id/like')
  likeStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.collectionsService.isImageLiked(user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/like')
  like(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.collectionsService.likeImage(user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id/like')
  unlike(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.collectionsService.unlikeImage(user.userId, id);
  }
}
