const { chromium } = require('playwright');

async function enableSemantics(page) {
  const ph = page.locator('flt-semantics-placeholder');
  if (await ph.count()) {
    await ph.focus();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1000);
  }
}

async function snapshot(page, label) {
  const nodes = await page.locator('flt-semantics').evaluateAll((els) =>
    els
      .map((el) => {
        const r = el.getBoundingClientRect();
        const text = (el.getAttribute('aria-label') || el.textContent || '').trim();
        return {
          text,
          role: el.getAttribute('role'),
          x: Math.round(r.x),
          y: Math.round(r.y),
          w: Math.round(r.width),
          h: Math.round(r.height),
        };
      })
      .filter((x) => x.text)
  );
  console.log(`\n--- ${label} ---`);
  for (const n of nodes) {
    console.log(`${n.role || 'text'}: "${n.text}" @ ${n.x},${n.y} ${n.w}x${n.h}`);
  }
  return nodes;
}

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  for (const [name, width, height] of [
    ['desktop', 1440, 900],
    ['tablet', 900, 1000],
    ['mobile', 390, 844],
  ]) {
    const page = await browser.newPage({ viewport: { width, height } });
    const errors = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error' || msg.text().includes('overflowed')) {
        errors.push(msg.text());
      }
    });
    page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
    await page.goto('http://127.0.0.1:8099', { waitUntil: 'load' });
    await page.waitForTimeout(9000);
    await enableSemantics(page);
    await snapshot(page, `${name} login`);
    await page.screenshot({ path: `review-${name}-login.png` });

    // Wrong-credential submit exercises validation, loading and error toast.
    await page.locator('input[aria-label="أدخل البريد الإلكتروني"]').fill('not-a-user@example.com');
    await page.locator('input[aria-label="أدخل كلمة المرور"]').fill('wrong-password');
    await page.getByRole('button', { name: 'تسجيل الدخول' }).click();
    await page.waitForTimeout(4000);
    await snapshot(page, `${name} after invalid login`);
    await page.screenshot({ path: `review-${name}-login-error.png` });

    // Registration dialog.
    const register = page.getByRole('button', { name: 'إنشاء حساب جديد' });
    if (await register.count()) {
      await register.click();
      await page.waitForTimeout(1500);
      await snapshot(page, `${name} register dialog`);
      await page.screenshot({ path: `review-${name}-register.png` });
    }

    console.log(`\nERRORS ${name}: ${errors.length}`);
    for (const e of errors.slice(0, 10)) console.log(e.slice(0, 500));
    await page.close();
  }
  await browser.close();
})();
