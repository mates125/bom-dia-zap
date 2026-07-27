import { Controller, Post, UseGuards } from '@nestjs/common';
import { ContentService } from './content.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

// TEMPORÁRIO: só existe pra forçar um lote de geração de conteúdo fora do
// cron de 6h (usado uma vez pra popular sourceUrl em imagens novas depois
// da correção do bug do fundo do editor premium). Remover depois de usar.
@UseGuards(JwtAuthGuard)
@Controller('content')
export class ContentController {
  constructor(private contentService: ContentService) {}

  @Post('generate-now')
  generateNow() {
    return this.contentService.generateForAllCategories();
  }
}
