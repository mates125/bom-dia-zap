FROM node:22-slim AS base

# libvips já vem com o pacote sharp; fontconfig é o que falta pra ele
# encontrar as fontes que instalamos abaixo.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Instala as fontes bundladas (Great Vibes, Poppins) no sistema, pra
# renderizar a mesma arte independente de plataforma.
RUN mkdir -p /usr/share/fonts/truetype/bomdiazap \
    && cp src/assets/fonts/*.ttf /usr/share/fonts/truetype/bomdiazap/ \
    && fc-cache -f

RUN npx prisma generate
RUN npm run build

EXPOSE 3000

CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
