// tools/audit-seo-registry.js
// Audit seo-registry.json for completeness and sitemap consistency.
// Usage:
//   node tools/audit-seo-registry.js [path/to/sitemap.xml]
// Example:
//   node tools/audit-seo-registry.js sitemap.xml

const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

function safeReadJson(p) {
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (e) {
    console.error('Failed to read/parse JSON', p, e.message);
    process.exit(1);
  }
}

async function parseSitemap(p) {
  try {
    const xml = fs.readFileSync(p, 'utf8');
    const parsed = await xml2js.parseStringPromise(xml);
    const urls = (parsed.urlset && parsed.urlset.url) || [];
    const locs = urls.map(u => (u.loc && u.loc[0]) || '').filter(Boolean);
    // extract slug values from query param 'slug' or last path segment if pretty URL
    const slugs = locs.map(l => {
      try {
        const u = new URL(l);
        if (u.searchParams.has('slug')) return u.searchParams.get('slug');
        // fallback: last path segment
        const seg = u.pathname.split('/').filter(Boolean).pop();
        return seg || null;
      } catch (e) {
        // maybe a relative URL or contains &amp; entities — try to parse slug param manually
        const q = l.split('?')[1] || '';
        const pairs = q.split('&').map(s=>s.replace(/&amp;/g,'&'));
        for (const p of pairs) {
          const [k,v] = p.split('=');
          if (k=== 'slug') return decodeURIComponent(v||'');
        }
        const seg = l.split('/').filter(Boolean).pop();
        return seg || null;
      }
    }).filter(Boolean);
    return { locs, slugs };
  } catch (e) {
    console.error('Failed to read/parse sitemap', p, e.message);
    return { locs: [], slugs: [] };
  }
}

(async () => {
  const repoRoot = path.join(__dirname, '..');
  const registryPath = path.join(repoRoot, 'seo-registry.json');
  if (!fs.existsSync(registryPath)) {
    console.error('seo-registry.json not found at', registryPath);
    process.exit(1);
  }

  const registry = safeReadJson(registryPath);
  if (!Array.isArray(registry)) {
    console.error('seo-registry.json must be an array of entries');
    process.exit(1);
  }

  const sitemapArg = process.argv[2] || path.join(repoRoot, 'sitemap.xml');
  let sitemap = { locs: [], slugs: [] };
  if (fs.existsSync(sitemapArg)) {
    sitemap = await parseSitemap(sitemapArg);
  } else {
    console.warn('Sitemap not found at', sitemapArg, '- sitemap checks will be skipped');
  }

  const report = {
    generatedAt: new Date().toISOString(),
    registryPath,
    registryCount: registry.length,
    missingFields: [],
    duplicateSlugs: [],
    entriesUsingDefaultValue: [],
    sitemapPath: fs.existsSync(sitemapArg) ? sitemapArg : null,
    sitemapUrlCount: sitemap.locs.length,
    sitemapSlugCount: sitemap.slugs.length,
    sitemapSlugsMissingInRegistry: [],
    registrySlugsNotInSitemap: []
  };

  const slugMap = new Map();
  for (let i = 0; i < registry.length; i++) {
    const e = registry[i];
    const idx = i;
    const slug = (e && e.slug) ? String(e.slug).trim() : '';
    // detect defaultValue usage
    if (Object.prototype.hasOwnProperty.call(e, 'defaultValue')) {
      report.entriesUsingDefaultValue.push({ index: idx, slug: slug || null, defaultValue: e.defaultValue });
    }
    // required fields: slug, (category or categoryId), from, to, value or defaultValue
    const hasCategory = Boolean((e.categoryId && String(e.categoryId).trim()) || (e.category && String(e.category).trim()));
    const hasFrom = Boolean(e.from && String(e.from).trim());
    const hasTo = Boolean(e.to && String(e.to).trim());
    const hasValue = Object.prototype.hasOwnProperty.call(e, 'value') || Object.prototype.hasOwnProperty.call(e, 'defaultValue');
    const missing = [];
    if (!slug) missing.push('slug');
    if (!hasCategory) missing.push('category/categoryId');
    if (!hasFrom) missing.push('from');
    if (!hasTo) missing.push('to');
    if (!hasValue) missing.push('value/defaultValue');
    if (missing.length) {
      report.missingFields.push({ index: idx, slug: slug || null, missing });
    }

    if (slug) {
      if (!slugMap.has(slug)) slugMap.set(slug, []);
      slugMap.get(slug).push({ index: idx, entry: e });
    }
  }

  // duplicates
  for (const [slug, arr] of slugMap.entries()) {
    if (arr.length > 1) report.duplicateSlugs.push({ slug, occurrences: arr.map(a=>a.index) });
  }

  // sitemap checks
  if (sitemap.slugs.length) {
    const registrySlugs = new Set(Array.from(slugMap.keys()));
    const sitemapSet = new Set(sitemap.slugs);
    for (const s of sitemapSet) {
      if (!registrySlugs.has(s)) report.sitemapSlugsMissingInRegistry.push(s);
    }
    for (const r of registrySlugs) {
      if (!sitemapSet.has(r)) report.registrySlugsNotInSitemap.push(r);
    }
  }

  const outPath = path.join(repoRoot, 'tools', 'audit-seo-registry-report.json');
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');

  console.log('Audit complete. Registry entries:', report.registryCount);
  console.log('Missing fields entries:', report.missingFields.length);
  console.log('Entries using defaultValue:', report.entriesUsingDefaultValue.length);
  console.log('Duplicate slugs found:', report.duplicateSlugs.length);
  if (report.sitemapPath) {
    console.log('Sitemap URL count:', report.sitemapUrlCount, 'Sitemap slug count:', report.sitemapSlugCount);
    console.log('Sitemap slugs missing in registry:', report.sitemapSlugsMissingInRegistry.length);
    console.log('Registry slugs not in sitemap:', report.registrySlugsNotInSitemap.length);
  }
  console.log('Report written to', outPath);
})();
