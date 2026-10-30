const { chromium } = require('playwright');

async function enableSemantics(page) {
  const ph = page.locator('flt-semantics-placeholder');
  if (await ph.count()) {
    await ph.focus();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(800);
  }
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
      .filter((n) => n.text && n.w > 0 && n.h > 0 && n.text.length < 120)
  );
}

async function clickLabel(page, label) {
  const loc = page.locator(`[aria-label="${label}"]`);
  if (await loc.count()) {
    await loc.first().click({ force: true });
    return true;
  }
  const text = page.getByText(label, { exact: true });
  if (await text.count()) {
    await text.first().click({ force: true });
    return true;
  }
  return false;
}

async function inspect(page, name) {
  const list = await nodes(page);
  const seen = new Set();
  const unique = list.filter((n) => {
    const key = `${n.text}@${n.x},${n.y}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
  console.log(`\n=== ${name} (${unique.length} semantics) ===`);
  for (const n of unique.slice(0, 55)) {
    console.log(`${n.role || 'text'} "${n.text}" @ ${n.x},${n.y} ${n.w}x${n.h}`);
  }
  await page.screenshot({ path: `preview-${name}.png`, fullPage: false });
}

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const sizes = [
    ['desktop', 1440, 900],
    ['tablet', 900, 1000],
    ['rail', 720, 900],
    ['mobile', 390, 844],
    ['tiny', 320, 720],
  ];
  for (const [name, width, height] of sizes) {
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
    await page.waitForTimeout(9000);
    await enableSemantics(page);
    await page.waitForTimeout(1000);
    await inspect(page, `${name}-dashboard`);

    if (name === 'desktop' || name === 'mobile') {
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
      if (name === 'mobile') {
        for (const [label, slug] of destinations.slice(0, 3)) {
          await clickLabel(page, 'القائمة');
          await page.waitForTimeout(500);
          const clicked = await clickLabel(page, label);
          await page.waitForTimeout(1200);
          console.log(`mobile nav ${label}: clicked=${clicked}`);
          await inspect(page, `${name}-${slug}`);
          if (slug === 'dashboard-again') break;
        }
      } else {
        for (const [label, slug] of destinations) {
          const clicked = await clickLabel(page, label);
          await page.waitForTimeout(1200);
          console.log(`desktop nav ${label}: clicked=${clicked}`);
          await inspect(page, `${name}-${slug}`);
        }
        // Browser back should pop the pushed destination, not the shell.
        await page.goBack({ waitUntil: 'commit' }).catch(() => {});
        await page.waitForTimeout(1000);
        await inspect(page, `${name}-browser-back`);
      }
    }

    console.log(`ERRORS ${name}: ${errors.length}`);
    for (const error of errors.slice(0, 12)) {
      console.log(error.slice(0, 600));
    }
    await page.close();
  }
  await browser.close();
})();
