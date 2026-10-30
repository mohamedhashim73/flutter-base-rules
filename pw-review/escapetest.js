const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await waitApp(page);
 await page.getByRole('button',{name:/بطاقات الائتمان/}).first().click();await page.waitForTimeout(1200);
 console.log('before',await page.getByRole('button',{name:/حساب المستخدم/}).count());
 await page.getByRole('button',{name:/إضافة بطاقة/}).first().click();await page.waitForTimeout(900);
 console.log('dialog',await page.getByRole('button',{name:/حساب المستخدم/}).count(),await page.getByRole('button',{name:/إغلاق/}).count());
 await page.keyboard.press('Escape');await page.waitForTimeout(1000);
 console.log('after esc',await page.getByRole('button',{name:/حساب المستخدم/}).count(),await page.getByRole('button',{name:/إضافة بطاقة/}).count());
 console.log('texts',await page.locator('flt-semantics').evaluateAll(els=>els.map(e=>e.textContent.trim()).filter(t=>t.includes('حساب')||t.includes('إضافة بطاقة')||t.includes('حفظ'))));
 await page.screenshot({path:'escape-after.png'});
 await browser.close();
})();
