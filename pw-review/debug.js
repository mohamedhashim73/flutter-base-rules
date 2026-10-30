const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const logs = [];
  page.on('console', (msg) => logs.push(`${msg.type()}: ${msg.text()}`));
  page.on('pageerror', (err) => logs.push(`pageerror: ${err.message}\n${err.stack}`));
  await page.goto('http://127.0.0.1:8099', { waitUntil: 'load' });
  for (let i = 0; i < 6; i++) {
    await page.waitForTimeout(3000);
    console.log(
      `t=${(i + 1) * 3}s`,
      'canvas=', await page.locator('canvas').count(),
      'glass=', await page.locator('flt-glass-pane').count(),
      'sem=', await page.locator('flt-semantics').count(),
      'body=', (await page.locator('body').innerHTML()).length
    );
  }
  await page.screenshot({ path: '/Users/muhammedhashim/Desktop/Projects/credixa/pw-review/debug.png' });
  console.log('\nLOGS:\n' + logs.join('\n').slice(0, 8000));
  console.log('\nBODY:\n' + (await page.locator('body').innerHTML()).slice(0, 3000));
  await browser.close();
})();
