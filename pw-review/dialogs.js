const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
async function snap(page,name){const list=await page.locator('flt-semantics').evaluateAll(els=>els.map(e=>({t:(e.getAttribute('aria-label')||e.textContent||'').trim(),r:e.getAttribute('role'),b:e.getBoundingClientRect().toJSON()})).filter(n=>n.t&&n.t.length<180&&n.b.width>0&&n.b.height>0));const seen=new Set();console.log(`\n== ${name} ==`);for(const n of list){const k=n.t+'@'+n.b.x+','+n.b.y;if(seen.has(k))continue;seen.add(k);console.log(`${n.r||'text'} "${n.t}" @ ${Math.round(n.b.x)},${Math.round(n.b.y)} ${Math.round(n.b.width)}x${Math.round(n.b.height)}`);}await page.screenshot({path:name+'.png'});}
async function open(page,name,label){const b=page.getByRole('button',{name:new RegExp(label)}).first();console.log('button',label,await b.count());if(await b.count()){await b.click();await page.waitForTimeout(900);await snap(page,name);await page.keyboard.press('Escape');await page.waitForTimeout(400);}}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [vp,w,h] of [['desktop',1440,900],['mobile',390,844]]){
  const page=await browser.newPage({viewport:{width:w,height:h}});
  const errors=[];page.on('console',m=>{const t=m.text();if(m.type()==='error'||t.includes('overflowed'))errors.push(t)});page.on('pageerror',e=>errors.push(e.message));
  await waitApp(page);
  if(vp==='mobile'){await page.getByRole('button',{name:'القائمة'}).first().click();await page.waitForTimeout(500);}
  await page.getByRole('button',{name:/بطاقات الائتمان/}).first().click();await page.waitForTimeout(1200);
  await open(page,`${vp}-add-card`,'إضافة بطاقة');
  if(vp==='mobile'){await page.getByRole('button',{name:'القائمة'}).first().click();await page.waitForTimeout(500);}
  await page.getByRole('button',{name:/مركز الاعتمادات/}).first().click();await page.waitForTimeout(1200);
  await open(page,`${vp}-approve`,'اعتماد');
  if(vp==='mobile'){await page.getByRole('button',{name:'القائمة'}).first().click();await page.waitForTimeout(500);}
  await page.getByRole('button',{name:/التقارير والتصدير/}).first().click();await page.waitForTimeout(1200);
  await open(page,`${vp}-export`,'تصدير التقرير');
  if(vp==='mobile'){await page.getByRole('button',{name:'القائمة'}).first().click();await page.waitForTimeout(500);}
  await page.getByRole('button',{name:/إدارة الكتالوجات/}).first().click();await page.waitForTimeout(1200);
  await open(page,`${vp}-catalog-add`,'إضافة');
  console.log('ERRORS',vp,errors.length,errors.slice(0,6));
  await page.close();
 }
 await browser.close();
})();
