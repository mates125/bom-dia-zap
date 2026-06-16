import { Injectable } from '@nestjs/common';
import { BrowserService } from '../../browser/browser.service';

interface ScrapedImage {
  src: string;
  alt: string;
  width: number;
  height: number;
}

@Injectable()
export class PensadorProvider {
  constructor(
    private browserService: BrowserService,
  ) {}

  async scrapeCategory(url: string,): Promise<ScrapedImage[]> {
    const browser =
      await this.browserService.getBrowser();

    const allImages: ScrapedImage[] = [];

    for (let currentPage = 1;
      currentPage <= 5;
      currentPage++) {

      const page = await browser.newPage();

      const pageUrl =
        `${url}${currentPage}/`;

      console.log(
        `Scrapeando página ${currentPage}`,
      );

      await page.goto(pageUrl, {
        waitUntil: 'domcontentloaded',
      });

      const images = await page.$$eval(
        'img',
        (elements) => {
          return elements
            .map((img) => ({
              src: img.src,
              alt: img.alt,
              width: img.width,
              height: img.height,
            }))
            .filter((img) => {
              return (
                img.src &&
                img.src.startsWith('http') &&
                img.width > 200 &&
                img.height > 200
              );
            });
        },
      );

      allImages.push(...images);

      await page.close();
    }
    return allImages;
  }
}