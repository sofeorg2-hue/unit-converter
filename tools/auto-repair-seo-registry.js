// tools/auto-repair-seo-registry.js
// Automatic best-effort repair of seo-registry.json
// - Normalizes `defaultValue` -> `value`
// - Removes exact-duplicate slug entries (keeps the most complete one)
// - Fills a few well-known missing entries heuristically (e.g., "acre-to-hectare")
// - Writes a backup of the original (seo-registry.json.bak) and overwrites seo-registry.json
// - Prints a short report to stdout and writes tools/auto-repair-report.json

const fs = require('fs');
const path = require('path');

const repoRoot = path.join(__dirname, '..');
const registryPath = path.join(repoRoot, 'seo-registry.json');
if (!fs.existsSync(registryPath)) {
  console.error('seo-registry.json not found in repo root');
  process.exit(1);
}

const raw = fs.readFileSync(registryPath, 'utf8');
let list;
try { list = JSON.parse(raw); } catch (e) { console.error('Failed to parse seo-registry.json:', e.message); process.exit(1); }

const report = { generatedAt: new Date().toISOString(), originalCount: list.length, fixedEntries: [], removedDuplicates: [], filledEntries: [] };

// Helper: clone
function clone(x) { return JSON.parse(JSON.stringify(x)); }

// Normalize entries and index by slug, prefer more complete entries
const slugMap = new Map();
for (let i = 0; i < list.length; i++) {
  const e = clone(list[i]);
  // normalize keys
  if (Object.prototype.hasOwnProperty.call(e, 'defaultValue') && !Object.prototype.hasOwnProperty.call(e, 'value')) {
    e.value = e.defaultValue;
    delete e.defaultValue;
    report.fixedEntries.push({ index: i, slug: e.slug || null, change: 'defaultValue->value' });
  }
  // trim strings
  ['slug','category','categoryId','from','to','title'].forEach(k=>{ if (e[k] && typeof e[k]==='string') e[k]=e[k].trim(); });

  const slug = e.slug || '';
  if (!slug) {
    // keep as-is for manual review
    if (!slugMap.has('__no_slug__')) slugMap.set('__no_slug__', []);
    slugMap.get('__no_slug__').push({entry:e,origIndex:i});
    continue;
  }
  if (!slugMap.has(slug)) slugMap.set(slug, []);
  slugMap.get(slug).push({entry: e, origIndex: i});
}

// Resolve duplicates: pick the entry with the most non-empty required fields (category/from/to/value)
function completenessScore(entry) {
  let s = 0;
  if (entry.slug) s++;
  if (entry.category || entry.categoryId) s++;
  if (entry.from) s++;
  if (entry.to) s++;
  if (Object.prototype.hasOwnProperty.call(entry,'value')) s++;
  return s;
}

const repaired = [];
for (const [slug, arr] of slugMap.entries()) {
  if (slug === '__no_slug__') {
    // just append these entries unchanged
    for (const a of arr) repaired.push(a.entry);
    continue;
  }
  if (arr.length === 1) { repaired.push(arr[0].entry); continue; }
  // multiple entries for same slug
  arr.sort((a,b)=>completenessScore(b.entry)-completenessScore(a.entry));
  const keeper = arr[0].entry;
  repaired.push(keeper);
  const removed = arr.slice(1).map(x=>x.origIndex);
  report.removedDuplicates.push({ slug, keptIndex: arr[0].origIndex, removedIndices: removed });
}

// Heuristic fills for known empty entries
function applyHeuristics(entries, report) {
  // map of known slug -> {category, from, to, value, title}
  const known = {
    'acre-to-hectare': { category: 'area', from: 'acre', to: 'hectare', value: 1, title: 'Acre to Hectare Converter - Agriculture Land Area Formula and FAQ' },
    'acre-to-hectares': { category: 'area', from: 'acre', to: 'hectare', value: 1, title: 'Area Acres to Hectares Converter | Universal Converter' },
    'acres-to-hectares': { category: 'area', from: 'acre', to: 'hectare', value: 1, title: 'Area Acres to Hectares Converter | Universal Converter' }
  };
  for (let i=0;i<entries.length;i++) {
    const e = entries[i];
    if (!e.slug) continue;
    const key = e.slug;
    if ((!(e.category||e.categoryId) || !e.from || !e.to) && known[key]) {
      const k = known[key];
      e.category = e.category || k.category;
      e.from = e.from || k.from;
      e.to = e.to || k.to;
      if (!Object.prototype.hasOwnProperty.call(e,'value')) e.value = k.value;
      if (!e.title) e.title = k.title;
      report.filledEntries.push({ index: i, slug: e.slug, applied: 'known-heuristic' });
    }
  }
}

applyHeuristics(repaired, report);

// Final validation pass: ensure uniqueness and consistency
const finalSlugs = new Set();
const finalList = [];
for (let i=0;i<repaired.length;i++) {
  const e = repaired[i];
  if (e.slug) {
    if (finalSlugs.has(e.slug)) {
      // skip duplicates
      report.removedDuplicates.push({ slug: e.slug, note: 'duplicate after heuristics, skipped' });
      continue;
    }
    finalSlugs.add(e.slug);
  }
  finalList.push(e);
}

// backup original
const bakPath = registryPath + '.bak.' + Date.now();
fs.writeFileSync(bakPath, JSON.stringify(list, null, 2), 'utf8');
fs.writeFileSync(registryPath, JSON.stringify(finalList, null, 2), 'utf8');
fs.writeFileSync(path.join(repoRoot, 'tools', 'auto-repair-report.json'), JSON.stringify(report, null, 2), 'utf8');

console.log('Auto-repair complete');
console.log('Original entries:', report.originalCount, 'Final entries:', finalList.length);
console.log('Fixed entries:', report.fixedEntries.length, 'Removed duplicate groups:', report.removedDuplicates.length, 'Filled entries:', report.filledEntries.length);
console.log('Backup saved to', bakPath);
console.log('Report written to tools/auto-repair-report.json');
