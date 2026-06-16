import {
  Injectable,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';

import {
  Browser,
  chromium,
} from 'playwright';

@Injectable()
export class BrowserService
  implements OnModuleInit, OnModuleDestroy {

  private browser: Browser;

  async onModuleInit() {
    this.browser = await chromium.launch({
      headless: true,
    });

    console.log('Browser initialized');
  }

  async onModuleDestroy() {
    if (this.browser) {
      await this.browser.close();
    }
  }

  async getBrowser() {
    if (!this.browser) {
      this.browser = await chromium.launch({
        headless: true,
      });
    }

    return this.browser;
  }
}