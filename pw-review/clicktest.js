const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto('http://127.0.0.1:8098', { waitUntil: 'load' });
  await page.waitForSelector('flt-semantics-placeholder', { timeout: 90000 });
  await page.locator('flt-semantics-placeholder').focus();
  await page.keyboard.press('Enter');
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 5);
  await page.waitForTimeout(800);
  for (const label of ['بطاقات الائتمان', 'التشغيل والخزينة', 'لوحة التحكم']) {
    console.log(label, 'aria', await page.locator(`[aria-label*="${label}"]`).count(), 'role', await page.getByRole('button', { name: label }).count(), 'role-regex', await page.getByRole('button', { name: new RegExp(label) }).count());
  }
  const el = page.getByRole('button', { name: /بطاقات الائتمان/ }).first();
  console.log('outer', await el.evaluate((e) => e.outerHTML.slice(0, 500)));
  await el.click();
  await page.waitForTimeout(1500);
  console.log('after', (await page.locator('flt-semantics').first().textContent()).slice(0, 200));
  await page.screenshot({ path: 'clicktest.png' });
  await browser.close();
})();
