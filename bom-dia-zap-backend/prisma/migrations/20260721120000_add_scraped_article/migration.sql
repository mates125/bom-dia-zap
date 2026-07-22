-- CreateTable
CREATE TABLE "ScrapedArticle" (
    "id" SERIAL NOT NULL,
    "url" TEXT NOT NULL,
    "scrapedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "categoryId" INTEGER NOT NULL,

    CONSTRAINT "ScrapedArticle_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ScrapedArticle_url_key" ON "ScrapedArticle"("url");

-- AddForeignKey
ALTER TABLE "ScrapedArticle" ADD CONSTRAINT "ScrapedArticle_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
