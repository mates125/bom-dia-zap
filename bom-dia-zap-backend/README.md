# Bom Dia Zap — Backend

API + gerador de conteúdo que alimenta o app **Bom Dia Zap**: um catálogo de imagens de "bom dia", "boa tarde", "boa noite", frases motivacionais, cristãs e de amor, para o app mobile baixar/compartilhar no WhatsApp.

O conteúdo é gerado automaticamente (a cada 6h): uma foto real de banco de imagens é combinada com uma frase em português, sem depender de raspar imagens prontas de outros sites — sem intervenção manual.

## Stack

- [NestJS](https://nestjs.com/) + TypeScript
- [Prisma](https://www.prisma.io/) + PostgreSQL
- [Pexels API](https://www.pexels.com/api/) (fotos) + [Sharp](https://sharp.pixelplumbing.com/) (composição da imagem final)

## Pré-requisitos

- [Node.js](https://nodejs.org/) 20+
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (para rodar o Postgres)
- Uma API key gratuita da Pexels: [pexels.com/api](https://www.pexels.com/api/) (sem cartão, instantâneo)

## Passo a passo para rodar localmente

### 1. Clonar e instalar dependências

```bash
git clone https://github.com/mates125/bom-dia-zap.git
cd bom-dia-zap/bom-dia-zap-backend
npm install
```

### 2. Subir o banco de dados

```bash
docker compose up -d
```

Isso sobe um Postgres em `localhost:5432` (usuário `postgres`, senha `postgres`, banco `bomdiazap`), conforme definido em [docker-compose.yml](docker-compose.yml).

### 3. Configurar as variáveis de ambiente

Crie um arquivo `.env` na raiz de `bom-dia-zap-backend/` com:

```bash
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/bomdiazap"
PEXELS_API_KEY="sua-api-key-da-pexels"
```

### 4. Rodar as migrations e o seed

```bash
npx prisma migrate deploy
npx prisma db seed
```

Isso cria as tabelas (`Category`, `Image`) e popula as categorias iniciais (bom-dia, boa-tarde, boa-noite, cristão, motivacional, amor).

### 5. Rodar a aplicação

```bash
npm run start:dev
```

A API sobe em `http://localhost:3000`.

### 6. Testar

- `GET /categories` — lista as categorias disponíveis.
- `GET /images?category=bom-dia&page=1&limit=20` — lista imagens paginadas, opcionalmente filtradas por categoria.
- `GET /generate` — dispara a geração de conteúdo manualmente (útil para testar sem esperar o agendamento automático de 6h em 6h).
- Imagens geradas ficam acessíveis em `http://localhost:3000/uploads/original/...` e `.../uploads/thumb/...`.

## Scripts úteis

```bash
npm run start:dev   # desenvolvimento com hot-reload
npm run build        # build de produção
npm run test          # testes unitários
npm run test:e2e     # testes end-to-end
npm run lint           # lint + fix
```

## Estrutura do projeto

```
src/
  content/     # geração de conteúdo: PexelsProvider, banco de frases, orquestração + agendamento
  categories/  # endpoint de categorias
  images/      # endpoint de imagens (paginado, filtrável por categoria)
  prisma/      # client do Prisma
  utils/       # composição da imagem final (foto + frase + marca)
uploads/       # imagens geradas (original + thumbnail) — não versionado, recriado a cada geração
prisma/        # schema, migrations e seed
```
