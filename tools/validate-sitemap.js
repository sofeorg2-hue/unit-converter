// tools/validate-sitemap.js
// Node script using Puppeteer to validate sitemap URLs redirect to the converter with correct params.

// Usage: 
//   npm install puppeteer xml2js axios
//   node tools/validate-sitemap.js <sitemap_url_or_path>

const fs = require('fs');
const path = require('path');
const axios = require('axios');
const xml2js = require('xml2js');
const puppeteer = require('puppeteer');

async function loadSitemap(input) {
  if (/^https?:\/\//.test(input)) {
    const r = await axios.get(input);
    return r.data;
  }
  return fs.readFileSync(input, 'utf8');
}

function parseLocs(xml) {
  return new Promise((resolve, reject) => {
    xml2js.parseString(xml, (err, result) => {
      if (err) return reject(err);
      const urls = (result.urlset && result.urlset.url) || [];
      const locs = urls.map(u => (u.loc && u.loc[0]) || '').filter(Boolean);
      resolve(locs);
    });
  });
}

function parseQueryParams(url) {
  try {
    const u = new URL(url);
    const params = {};
    u.searchParams.forEach((v,k)=>{ params[k]=v; });
    return params;
  } catch (e) {
    // maybe it's a relative path with encoded &amp;
    const q = url.split('?')[1] || '';
    const pairs = q.split('&').map(s=>s.replace(/&amp;/g,'&'));
    const params = {};
    pairs.forEach(p=>{ const [k,v]=p.split('='); if(k) params[k]=decodeURIComponent((v||'').replace(/^\/+|\/+$/g,'')); });
    return params;
  }
}

(async () => {
  const input = process.argv[2] || 'sitemap.xml';
  console.log('Loading sitemap:', input);
  const xml = await loadSitemap(input);
  const locs = await parseLocs(xml);
  console.log('Found', locs.length, 'URLs in sitemap');

  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  page.setDefaultNavigationTimeout(30000);

  const report = [];
  for (let i=0;i<locs.length;i++) {
    const loc = locs[i];
    process.stdout.write(`Testing ${i+1}/${locs.length}: ${loc} ... `);
    try {
      const response = await page.goto(loc, { waitUntil: 'networkidle2' });
      // follow redirects: final URL
      const final = page.url();
      const entry = { loc, final };
      const params = parseQueryParams(final);
      entry.params = params;
      // checks
      entry.openedConverter = final.includes('/converter') || final.includes('#converter');
      entry.hasCategory = !!(params.category);
      entry.hasFrom = !!(params.from);
      entry.hasTo = !!(params.to);
      entry.hasValue = !!(params.value) || !!(params.val);
      entry.hasSlug = !!(params.slug);
      entry.passed = entry.openedConverter && entry.hasCategory && entry.hasFrom && entry.hasTo && entry.hasSlug;
      if (entry.passed) process.stdout.write('OK\n'); else process.stdout.write('FAIL\n');
      report.push(entry);
    } catch (e) {
      console.error('ERROR', e.message);
      report.push({ loc, error: e.message, passed: false });
    }
  }

  await browser.close();
  const out = { generatedAt: new Date().toISOString(), total: locs.length, results: report };
  fs.writeFileSync('tools/validate-sitemap-report.json', JSON.stringify(out, null, 2));
  const failures = report.filter(r=>!r.passed);
  console.log('\nDone. Total:', locs.length, 'Failures:', failures.length);
  if (failures.length) console.log('See tools/validate-sitemap-report.json for details');
  process.exit(failures.length ? 2 : 0);
})();
