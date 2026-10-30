const { chromium } = require('playwright');

async function waitForApp(page) {
  await page.waitForSelector('flt-semantics-placeholder', { timeout: 90000 });
  await page.locator('flt-semantics-placeholder').focus();
  await page.keyboard.press('Enter');
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics').length > 5,
    { timeout: 30000 }
  );
  await page.waitForTimeout(800);
}

async function nodes(page) {
  return page.locator('flt-semantics').evaluateAll((els) =>
    els
      .map((el) => {
        const r = el.getBoundingClientRect();
        return {
          text: (el.getAttribute('aria-label') || el.textContent || '').trim(),
          role: el.getAttribute('role'),
          x: Math.round(r.x),
          y: Math.round(r.y),
          w: Math.round(r.width),
          h: Math.round(r.height),
        };
      })
      .filter((n) => n.text && n.w > 0 && n.h > 0 && n.text.length < 130)
  );
}

async function inspect(page, name, limit = 45) {
  const list = await nodes(page);
  const seen = new Set();
  const unique = list.filter((n) => {
    const key = `${n.text}@${n.x},${n.y}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
  console.log(`\n=== ${name} (${unique.length} semantics) ===`);
  for (const n of unique.slice(0, limit)) {
    console.log(`${n.role || 'text'} "${n.text}" @ ${n.x},${n.y} ${n.w}x${n.h}`);
  }
  await page.screenshot({ path: `preview-${name}.png` });
  return unique;
}

async function clickLabel(page, label) {
  const loc = page.getByRole('button', { name: new RegExp(label) });
  if (!(await loc.count())) return false;
  try {
    await loc.first().click({ timeout: 5000 });
  } catch {
    await loc.first().dispatchEvent('click');
  }
  return true;
}

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  for (const [name, width, height] of [
    ['desktop', 1440, 900],
    ['rail', 720, 900],
    ['mobile', 390, 844],
    ['tiny', 320, 720],
  ]) {
    const page = await browser.newPage({ viewport: { width, height } });
    const errors = [];
    page.on('console', (msg) => {
      const text = msg.text();
      if (msg.type() === 'error' || text.includes('overflowed') || text.includes('Exception')) {
        errors.push(text);
      }
    });
    page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
    await page.goto('http://127.0.0.1:8098', { waitUntil: 'load' });
    await waitForApp(page);
    await inspect(page, `${name}-dashboard`);

    const destinations = [
      ['بطاقات الائتمان', 'credit-cards'],
      ['التشغيل والخزينة', 'operations'],
      ['مركز الاعتمادات', 'approvals'],
      ['التقارير والتصدير', 'reports'],
      ['المستخدمون والإعدادات', 'users'],
      ['مركز الإشعارات', 'notifications'],
      ['سجل التدقيق', 'audit'],
      ['إدارة الكتالوجات', 'catalogs'],
      ['لوحة التحكم', 'dashboard-again'],
    ];
    for (const [label, slug] of destinations) {
      if (name === 'mobile' || name === 'tiny') {
        const menu = await clickLabel(page, 'القائمة');
        if (!menu) {
          console.log(`${name}: menu button not found`);
          break;
        }
        await page.waitForTimeout(600);
      }
      const clicked = await clickLabel(page, label);
      await page.waitForTimeout(1400);
      console.log(`\n${name} nav "${label}" clicked=${clicked}`);
      await inspect(page, `${name}-${slug}`, 30);
    }

    if (name === 'desktop' || name === 'rail') {
      await page.goBack({ waitUntil: 'commit' }).catch(() => {});
      await page.waitForTimeout(1200);
      await inspect(page, `${name}-browser-back`, 25);
    }

    console.log(`\nERRORS ${name}: ${errors.length}`);
    for (const error of errors.slice(0, 12)) console.log(error.slice(0, 600));
    await page.close();
  }
  await browser.close();
})();
