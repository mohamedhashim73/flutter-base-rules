const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await waitApp(page);
 await page.getByRole('button',{name:/بطاقات الائتمان/}).first().click();
 await page.waitForTimeout(1800);
 const groups=page.locator('flt-semantics[role="group"]');
 console.log('groups',await groups.count());
 const html=await groups.first().evaluate(e=>e.outerHTML);
 console.log(html.slice(0,3000));
 console.log('---account buttons---');
 const acct=page.getByRole('button',{name:/حساب المستخدم/});
 console.log('count',await acct.count());
 for(let i=0;i<await acct.count();i++){
   console.log(i, await acct.nth(i).evaluate(e=>e.outerHTML.slice(0,700)));
 }
 await page.screenshot({path:'credit-header.png'});
 await browser.close();
})();
