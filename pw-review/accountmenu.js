const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await waitApp(page);
 const acct=page.getByRole('button',{name:/حساب المستخدم/}).first();
 console.log('acct box',await acct.boundingBox(),await acct.count());
 await acct.click();
 await page.waitForTimeout(800);
 const txt=await page.locator('flt-semantics').evaluateAll(els=>els.map(e=>e.textContent.trim()).filter(t=>t.includes('الملف الشخصي')||t.includes('تسجيل الخروج')||t.includes('البريد')));
 console.log('menu',JSON.stringify(txt));
 console.log('menu buttons',await page.getByRole('menuitem').count());
 await page.screenshot({path:'account-menu.png'});
 await browser.close();
})();
