import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const categories = [
    {
      name: 'Bom Dia',
      slug: 'bom-dia',
    },
    {
      name: 'Boa Tarde',
      slug: 'boa-tarde',
    },
    {
      name: 'Boa Noite',
      slug: 'boa-noite',
    },
    {
      name: 'Cristão',
      slug: 'cristao',
    },
    {
      name: 'Motivacional',
      slug: 'motivacional',
    },
    {
      name: 'Amor',
      slug: 'amor',
    },
  ];

  for (const category of categories) {
    await prisma.category.upsert({
      where: {
        slug: category.slug,
      },
      update: {},
      create: category,
    });
  }

  const bomDia = await prisma.category.findFirst({
    where: {
      slug: 'bom-dia',
    },
  });

  if (bomDia) {
    await prisma.image.upsert({
      where: {
        hash: 'imagem-teste-1',
      },

      update: {},

      create: {
        title: 'Bom dia com café',
        imageUrl: 'https://placehold.co/600x800',
        thumbnailUrl: 'https://placehold.co/300x400',
        sourceUrl: 'https://example.com',
        hash: 'imagem-teste-1',
        categoryId: bomDia.id,
      },
    });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });