import { PrismaClient } from '@prisma/client';
import { PHRASE_BANK } from '../src/content/phrase-bank';

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

  for (const [categorySlug, phrases] of Object.entries(PHRASE_BANK)) {
    const category = await prisma.category.findFirst({
      where: { slug: categorySlug },
    });

    if (!category) {
      continue;
    }

    await prisma.phrase.createMany({
      data: phrases.map((text) => ({
        text,
        source: 'curated',
        categoryId: category.id,
      })),
      skipDuplicates: true,
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
