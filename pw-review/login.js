const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  for (const [name, width, height] of [
    ['login-desktop', 1440, 900],
    ['login-tablet', 900, 1000],
    ['login-mobile', 390, 844],
  ]) {
    const page = await browser.newPage({ viewport: { width, height } });
    const logs = [];
    page.on('console', (msg) => logs.push(`${msg.type()}: ${msg.text()}`));
    page.on('pageerror', (err) => logs.push(`pageerror: ${err.message}`));
    await page.goto('http://127.0.0.1:8099', { waitUntil: 'load' });
    await page.waitForTimeout(12000);
    const placeholder = page.locator('flt-semantics-placeholder');
    if (await placeholder.count()) {
      await placeholder.evaluate((el) => el.click());
    }
    await page.waitForTimeout(1500);
    await page.screenshot({ path: `/Users/muhammedhashim/Desktop/Projects/credixa/pw-review/${name}.png` });
    const texts = await page.locator('flt-semantics').evaluateAll((els) =>
      els
        .map((el) => ({
          role: el.getAttribute('role'),
          label: el.getAttribute('aria-label'),
          text: el.textContent,
          rect: el.getBoundingClientRect().toJSON(),
        }))
        .filter((x) => x.label || (x.text && x.text.trim()))
        .slice(0, 40)
    );
    console.log(`\n=== ${name} canvas=${await page.locator('canvas').count()} ===`);
    console.log(JSON.stringify(texts, null, 1));
    console.log(logs.filter((l) => !l.includes('favicon') && !l.includes('debug:')).slice(0, 15).join('\n'));
    await page.close();
  }
  await browser.close();
})();
