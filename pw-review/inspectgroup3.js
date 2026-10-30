const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await waitApp(page);
 await page.getByRole('button',{name:/بطاقات الائتمان/}).first().click();
 await page.waitForTimeout(1800);
 const host=await page.locator('flt-semantics-host').innerHTML();
 let i=-1,n=0;
 while((i=host.indexOf('حساب المستخدم',i+1))>=0){console.log('occ',++n,'at',i); if(n>1) console.log(host.slice(i-1200,i+400));}
 console.log('groups:');
 const groups=page.locator('flt-semantics[role="group"]');
 console.log('count',await groups.count());
 for(let g=0;g<await groups.count();g++){
  const t=await groups.nth(g).textContent();
  const box=await groups.nth(g).boundingBox();
  console.log(g, box, t.slice(0,150).replace(/\n/g,' | '));
 }
 await browser.close();
})();
