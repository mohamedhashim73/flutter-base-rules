const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
async function snap(page,name,limit=40){const list=await page.locator('flt-semantics').evaluateAll(els=>els.map(e=>({t:(e.getAttribute('aria-label')||e.textContent||'').trim(),r:e.getAttribute('role'),b:e.getBoundingClientRect().toJSON()})).filter(n=>n.t&&n.t.length<180&&n.b.width>0&&n.b.height>0));const seen=new Set();console.log(`\n== ${name} ==`);let i=0;for(const n of list){const k=n.t+'@'+n.b.x+','+n.b.y;if(seen.has(k))continue;seen.add(k);if(i++>limit)continue;console.log(`${n.r||'text'} "${n.t}" @ ${Math.round(n.b.x)},${Math.round(n.b.y)} ${Math.round(n.b.width)}x${Math.round(n.b.height)}`);}await page.screenshot({path:name+'.png'});}
async function click(page,label){const b=page.getByRole('button',{name:new RegExp(label)}).first();console.log('click',label,await b.count(),await b.boundingBox().catch(()=>null));if(await b.count())await b.click();await page.waitForTimeout(900);}
async function nav(page,label,mobile){if(mobile){await page.getByRole('button',{name:'القائمة'}).first().click();await page.waitForTimeout(500);}await click(page,label);}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [vp,w,h] of [['desktop',1440,900],['mobile',390,844],['tiny',320,720]]){
  const page=await browser.newPage({viewport:{width:w,height:h}});
  const errors=[];page.on('console',m=>{const t=m.text();if(m.type()==='error'||t.includes('overflowed'))errors.push(t)});page.on('pageerror',e=>errors.push(e.message));
  await waitApp(page);
  const mobile=vp!=='desktop';
  await nav(page,'بطاقات الائتمان',mobile);
  await click(page,'إضافة بطاقة');
  await snap(page,`${vp}-add-card`,18);
  await page.keyboard.press('Escape');await page.waitForTimeout(500);
  // profile
  if(vp==='mobile'||vp==='tiny'){
    const acct=page.getByRole('button',{name:/حساب المستخدم/}).first();
    await acct.click();await page.waitForTimeout(500);
  } else {
    const acct=page.getByRole('button',{name:/حساب المستخدم/}).first();await acct.click();await page.waitForTimeout(500);
  }
  await click(page,'الملف الشخصي');
  await snap(page,`${vp}-profile`,20);
  await page.keyboard.press('Escape');await page.waitForTimeout(500);
  // approvals reject prompt
  await nav(page,'مركز الاعتمادات',mobile);
  await click(page,'رفض');
  await snap(page,`${vp}-reject-prompt`,25);
  await page.keyboard.press('Escape');await page.waitForTimeout(500);
  // notifications preferences
  await nav(page,'مركز الإشعارات',mobile);
  console.log(`${vp} notification buttons`,await page.getByRole('button').evaluateAll(els=>els.map(e=>e.textContent.trim()).filter(t=>t.length<40)));
  const pref=page.getByRole('button',{name:/تفضيلات/}).first();
  console.log('pref count',await pref.count());
  if(await pref.count()){await pref.click();await page.waitForTimeout(900);await snap(page,`${vp}-preferences`,30);await page.keyboard.press('Escape');await page.waitForTimeout(500);}
  console.log('ERRORS',vp,errors.length,errors.slice(0,5));
  await page.close();
 }
 await browser.close();
})();
