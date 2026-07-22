# Bom Dia Zap — Backend

API + scraper que alimenta o app **Bom Dia Zap**: um catálogo de imagens de "bom dia", "boa tarde", "boa noite" e frases motivacionais, coletadas automaticamente da internet e servidas para o app mobile baixar/compartilhar no WhatsApp.

O scraper roda sozinho (a cada 6h) descobrindo artigos novos nas categorias configuradas, baixando as imagens, gerando thumbnails e salvando tudo no Postgres — sem intervenção manual.

## Stack

- [NestJS](https://nestjs.com/) + TypeScript
- [Prisma](https://www.prisma.io/) + PostgreSQL
- [Playwright](https://playwright.dev/) (scraping) + [Sharp](https://sharp.pixelplumbing.com/) (compressão/thumbnail)

## Pré-requisitos

- [Node.js](https://nodejs.org/) 20+
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (para rodar o Postgres)

## Passo a passo para rodar localmente

### 1. Clonar e instalar dependências

```bash
git clone https://github.com/mates125/bom-dia-zap.git
cd bom-dia-zap/bom-dia-zap-backend
npm install
```

### 2. Baixar o navegador usado pelo scraper

O Playwright precisa de um Chromium próprio (não usa o navegador instalado no seu PC):

```bash
npx playwright install chromium
```

### 3. Subir o banco de dados

```bash
docker compose up -d
```

Isso sobe um Postgres em `localhost:5432` (usuário `postgres`, senha `postgres`, banco `bomdiazap`), conforme definido em [docker-compose.yml](docker-compose.yml).

### 4. Configurar as variáveis de ambiente

Crie um arquivo `.env` na raiz de `bom-dia-zap-backend/` com:

```bash
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/bomdiazap"
```

### 5. Rodar as migrations e o seed

```bash
npx prisma migrate deploy
npx prisma db seed
```

Isso cria as tabelas (`Category`, `Image`, `ScrapedArticle`) e populado as categorias iniciais (bom-dia, boa-tarde, boa-noite, motivacional).

### 6. Rodar a aplicação

```bash
npm run start:dev
```

A API sobe em `http://localhost:3000`.

### 7. Testar

- `GET /categories` — lista as categorias disponíveis.
- `GET /images?category=bom-dia&page=1&limit=20` — lista imagens paginadas, opcionalmente filtradas por categoria.
- `GET /scrape` — dispara o scraping manualmente (útil para testar sem esperar o agendamento automático de 6h em 6h).
- Imagens baixadas ficam acessíveis em `http://localhost:3000/uploads/original/...` e `.../uploads/thumb/...`.

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
  browser/     # instância singleton do Playwright (Chromium headless)
  scraper/     # providers de scraping (ex: Pensador) + orquestração + agendamento
  categories/  # endpoint de categorias
  images/      # endpoint de imagens (paginado, filtrável por categoria)
  prisma/      # client do Prisma
  utils/       # download + compressão de imagens
uploads/       # imagens baixadas (original + thumbnail)
prisma/        # schema, migrations e seed
```
