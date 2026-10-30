const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await waitApp(page);
 for(const label of ['بطاقات الائتمان','التقارير والتصدير','مركز الإشعارات','لوحة التحكم']){
  await page.getByRole('button',{name:new RegExp(label)}).first().click();await page.waitForTimeout(1200);
  console.log('\n--',label,'account',await page.getByRole('button',{name:/حساب المستخدم/}).count());
  const groups=page.locator('flt-semantics[role="group"]');
  const arr=await groups.evaluateAll(els=>els.map(e=>{const b=e.getBoundingClientRect();return {t:e.textContent.trim().slice(0,110),x:Math.round(b.x),y:Math.round(b.y),w:Math.round(b.width),h:Math.round(b.height),tap:e.hasAttribute('flt-tappable'),exp:e.getAttribute('aria-expanded')}}).filter(o=>o.y<300));
  console.log(arr);
  const btns=await page.locator('flt-semantics[role="button"]').evaluateAll(els=>els.map(e=>{const b=e.getBoundingClientRect();return {t:e.textContent.trim(),x:Math.round(b.x),y:Math.round(b.y),w:Math.round(b.width),h:Math.round(b.height)}}).filter(o=>o.y<160&&o.x<1174));
  console.log(btns);
 }
 await page.screenshot({path:'headcheck.png'});
 await browser.close();
})();
