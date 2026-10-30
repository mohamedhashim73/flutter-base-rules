const { chromium } = require('playwright');

async function enableSemantics(page) {
  const ph = page.locator('flt-semantics-placeholder');
  if (await ph.count()) {
    await ph.focus();
    await page.keyboard.press('Enter');
  }
  await page.waitForSelector('input[aria-label="أدخل البريد الإلكتروني"]', { timeout: 60000 });
}

async function nodes(page) {
  return page.locator('flt-semantics').evaluateAll((els) =>
    els.map((el) => {
      const r = el.getBoundingClientRect();
      return { text: (el.getAttribute('aria-label') || el.textContent || '').trim(), role: el.getAttribute('role'), x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
    }).filter((x) => x.text && x.w > 0)
  );
}

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  for (const [name, width, height] of [['tablet', 900, 1000], ['mobile', 390, 844], ['tiny', 320, 720]]) {
    const page = await browser.newPage({ viewport: { width, height } });
    const errors = [];
    page.on('console', (msg) => { if (msg.type() === 'error' || msg.text().includes('overflowed')) errors.push(msg.text()); });
    page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
    await page.goto('http://127.0.0.1:8099', { waitUntil: 'load' });
    await page.waitForTimeout(9000);
    await enableSemantics(page);
    await page.waitForTimeout(800);
    console.log(`\n=== ${name} login ===`);
    for (const n of await nodes(page)) console.log(`${n.role || 'text'}: "${n.text}" @ ${n.x},${n.y} ${n.w}x${n.h}`);
    await page.screenshot({ path: `review-${name}-login.png` });
    await page.locator('input[aria-label="أدخل البريد الإلكتروني"]').fill('not-a-user@example.com');
    await page.locator('input[aria-label="أدخل كلمة المرور"]').fill('wrong-password');
    await page.getByRole('button', { name: 'تسجيل الدخول' }).click();
    await page.waitForTimeout(4000);
    console.log(`\n=== ${name} after error ===`);
    for (const n of await nodes(page)) console.log(`${n.role || 'text'}: "${n.text}" @ ${n.x},${n.y} ${n.w}x${n.h}`);
    await page.screenshot({ path: `review-${name}-error.png` });
    const register = page.getByRole('button', { name: 'إنشاء حساب جديد' });
    if (await register.count()) {
      await register.click();
      await page.waitForTimeout(1000);
      console.log(`\n=== ${name} register ===`);
      for (const n of await nodes(page)) console.log(`${n.role || 'text'}: "${n.text}" @ ${n.x},${n.y} ${n.w}x${n.h}`);
      await page.screenshot({ path: `review-${name}-register.png` });
    }
    console.log(`ERRORS ${name}: ${errors.length}`);
    errors.slice(0, 8).forEach((e) => console.log(e.slice(0, 400)));
    await page.close();
  }
  await browser.close();
})();
