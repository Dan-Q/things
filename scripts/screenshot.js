// Usage: node screenshot.js '<json array of {name,url,width,height,output}>'
const puppeteer = require('puppeteer');

(async () => {
  const jobs = JSON.parse(process.argv[2] || '[]');
  if (jobs.length === 0) return;
  const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  let failures = 0;
  for (const job of jobs) {
    const page = await browser.newPage();
    try {
      await page.setViewport({ width: job.width, height: job.height });
      await page.goto(job.url, { waitUntil: 'networkidle2', timeout: 30000 });
      await page.screenshot({ path: job.output, type: 'webp', quality: 80 });
      console.log(`   captured ${job.name}`);
    } catch (e) {
      failures++;
      console.error(`   FAILED ${job.name} (${job.url}): ${e.message}`);
    } finally {
      await page.close();
    }
  }
  await browser.close();
  if (failures > 0) process.exitCode = 1;
})().catch(e => { console.error(e); process.exit(1); });
