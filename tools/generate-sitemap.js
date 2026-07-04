// tools/generate-sitemap.js
// Regenerate sitemap.xml from seo-registry.json

const fs = require('fs');
const path = require('path');

const outPath = process.argv[2] || 'sitemap.xml';
const baseUrl = (process.argv[3] || 'https://theuniversalconverter.com').replace(/\/$/, '');

const registryPath = path.join(__dirname, '..', 'seo-registry.json');

function ensureEntry(e) {
  const category = e.categoryId || e.category || '';
  const from = e.from || '';
  const to = e.to || '';
  const slug = e.slug || '';
  const value = (e.value !== undefined ? e.value : (e.defaultValue !== undefined ? e.defaultValue : '1'));
  return { category, from, to, slug, value };
}

function makeLoc(entry) {
  const params = new URLSearchParams();
  params.set('category', entry.category);
  params.set('from', entry.from);
  params.set('to', entry.to);
  params.set('value', String(entry.value));
  params.set('slug', entry.slug);
  return `${baseUrl}/converter?${params.toString()}`;
}

function nowIso() {
  return new Date().toISOString().substring(0, 10);
}

function main() {
  const raw = fs.readFileSync(registryPath, 'utf8');
  let list;
  try {
    list = JSON.parse(raw);
  } catch (e) {
    console.error('Failed to parse seo-registry.json:', e.message);
    process.exit(1);
  }
  const urls = [];

  urls.push({ loc: `${baseUrl}/`, lastmod: nowIso(), changefreq: 'weekly' });
  urls.push({ loc: `${baseUrl}/#converter`, lastmod: nowIso(), changefreq: 'weekly' });

  for (const e of list) {
    if (!e || !e.slug) continue;
    const entry = ensureEntry(e);
    if (!entry.category || !entry.from || !entry.to || !entry.slug) continue;
    urls.push({ loc: makeLoc(entry), lastmod: nowIso(), changefreq: 'weekly' });
  }

  const xml = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'];
  for (const u of urls) {
    xml.push(`  <url><loc>${u.loc}</loc><lastmod>${u.lastmod}</lastmod><changefreq>${u.changefreq}</changefreq></url>`);
  }
  xml.push('</urlset>');
  fs.writeFileSync(outPath, xml.join('\n'), 'utf8');
  console.log('Wrote', outPath, 'with', urls.length, 'entries');
}

main();
