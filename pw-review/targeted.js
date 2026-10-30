const { chromium } = require('playwright');
async function waitApp(page){await page.goto('http://127.0.0.1:8098',{waitUntil:'load'});await page.waitForSelector('flt-semantics-placeholder',{timeout:90000});await page.locator('flt-semantics-placeholder').focus();await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelectorAll('flt-semantics').length>5);await page.waitForTimeout(800);}
async function navItems(page){
 return page.locator('flt-semantics[role="button"]').evaluateAll(els=>els.map(e=>{const r=e.getBoundingClientRect();return {name:e.textContent.trim(),x:Math.round(r.x),y:Math.round(r.y),w:Math.round(r.width),h:Math.round(r.height)}}).filter(n=>n.y<1000&&n.w===250));
}
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 for(const [name,width,height] of [['desktop',1440,900],['mobile',390,844],['tiny',320,720]]){
  const page=await browser.newPage({viewport:{width,height}});
  const errors=[];page.on('console',m=>{const t=m.text();if(m.type()==='error'||t.includes('overflowed'))errors.push(t)});page.on('pageerror',e=>errors.push(e.message));
  await waitApp(page);
  console.log(`\n== ${name} ==`);
  console.log('nav items',JSON.stringify(await navItems(page)));
  console.log('account buttons',await page.getByRole('button',{name:/حساب المستخدم/}).count());
  const group=page.locator('flt-semantics[role="group"][flt-tappable]');
  console.log('tappable groups',await group.count());
  for(const label of ['إدارة الكتالوجات','مركز الاعتمادات']){
    if(name!=='desktop'){await page.getByRole('button',{name:'القائمة'}).first().click();await page.waitForTimeout(500);}
    const btn=page.getByRole('button',{name:label}).first();
    console.log(label,'visible',await btn.isVisible(),'box',await btn.boundingBox());
    await btn.click();
    await page.waitForTimeout(1500);
    const top=await page.locator('flt-semantics').evaluateAll((els, label) => els.map(e=>e.textContent.trim()).find(t=>t.includes(label))||'', label);
    const header=await page.locator('flt-semantics[role="group"]').evaluateAll(els=>els.map(e=>e.textContent.trim()).filter(t=>t.length<200).slice(0,12));
    console.log('after',label,'found title',JSON.stringify(top),'groups',JSON.stringify(header));
    await page.screenshot({path:`target-${name}-${label.includes('كتالوج')?'catalogs':'approvals'}.png`});
  }
  console.log('errors',errors.length,errors.slice(0,5));
  await page.close();
 }
 await browser.close();
})();
