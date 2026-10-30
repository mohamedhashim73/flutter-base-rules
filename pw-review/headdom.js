const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:900}});
 await waitApp(page);
 await page.getByRole('button',{name:/بطاقات الائتمان/}).first().click();await page.waitForTimeout(1200);
 const html=await page.locator('flt-semantics').evaluateAll(els=>{
  const e=els.find(x=>{const b=x.getBoundingClientRect();return Math.round(b.x)===33&&Math.round(b.y)===29&&Math.round(b.width)===1108});
  return e?e.outerHTML:'none';
 });
 console.log(html.slice(0,5000));
 await browser.close();
})();
