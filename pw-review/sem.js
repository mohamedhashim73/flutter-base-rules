const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto('http://127.0.0.1:8099', { waitUntil: 'load' });
  await page.waitForTimeout(9000);
  const ph = page.locator('flt-semantics-placeholder');
  console.log('placeholder', await ph.count());
  await ph.focus();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(2000);
  console.log('sem', await page.locator('flt-semantics').count());
  console.log('host', await page.locator('flt-semantics-host').innerHTML());
  await page.screenshot({ path: 'login-desktop.png' });
  await browser.close();
})();
