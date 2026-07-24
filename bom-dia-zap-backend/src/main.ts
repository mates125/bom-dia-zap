import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();

  const port = process.env.PORT ?? 3000;

  // Precisa escutar em 0.0.0.0 (não só no host padrão) pra ser alcançável
  // de fora do container em plataformas como o Railway.
  await app.listen(port, '0.0.0.0');

  console.log(`Application is running on port ${port}`);
}
bootstrap();
