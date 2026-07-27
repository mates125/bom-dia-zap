import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

const SALT_ROUNDS = 10;
const LIKED_COLLECTION_NAME = 'Curtidas';

interface UserRecord {
  id: number;
  email: string;
  isPremium: boolean;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async register(email: string, password: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });

    if (existing) {
      throw new ConflictException('Este e-mail já está cadastrado');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        collections: {
          create: {
            name: LIKED_COLLECTION_NAME,
            isDefault: true,
          },
        },
      },
    });

    return this.buildAuthResponse(user);
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      throw new UnauthorizedException('E-mail ou senha inválidos');
    }

    return this.buildAuthResponse(user);
  }

  async getProfile(userId: number) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new UnauthorizedException();
    }

    return this.toPublicUser(user);
  }

  /**
   * TEMPORÁRIO: só existe pra testar o editor de imagem premium antes do
   * Google Play Billing estar pronto. Remover assim que a compra de verdade
   * estiver integrada — deixa qualquer usuário logado virar premium de graça.
   */
  async toggleDevPremium(userId: number) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { isPremium: !user.isPremium },
    });

    return this.toPublicUser(updated);
  }

  private buildAuthResponse(user: UserRecord) {
    const accessToken = this.jwtService.sign({ sub: user.id });

    return {
      accessToken,
      user: this.toPublicUser(user),
    };
  }

  private toPublicUser(user: UserRecord) {
    return {
      id: user.id,
      email: user.email,
      isPremium: user.isPremium,
    };
  }
}
