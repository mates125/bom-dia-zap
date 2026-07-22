-- DropForeignKey
ALTER TABLE "ScrapedArticle" DROP CONSTRAINT "ScrapedArticle_categoryId_fkey";

-- DropTable
DROP TABLE "ScrapedArticle";

-- AlterTable
ALTER TABLE "Image" ADD COLUMN "photographer" TEXT;
