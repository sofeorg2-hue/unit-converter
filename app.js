(function () {
  "use strict";

  const storageKeys = {
    theme: "uc-theme",
    favorites: "uc-favorites",
    recent: "uc-recent",
    searches: "uc-recent-searches",
    history: "uc-history",
    precision: "uc-precision",
    notation: "uc-notation",
    customUnits: "uc-custom-units",
    newsletter: "uc-newsletter"
  };

  const prefixes = [
    ["quetta", "Quetta", "Q", 1e30],
    ["ronna", "Ronna", "R", 1e27],
    ["yotta", "Yotta", "Y", 1e24],
    ["zetta", "Zetta", "Z", 1e21],
    ["exa", "Exa", "E", 1e18],
    ["peta", "Peta", "P", 1e15],
    ["tera", "Tera", "T", 1e12],
    ["giga", "Giga", "G", 1e9],
    ["mega", "Mega", "M", 1e6],
    ["kilo", "Kilo", "k", 1e3],
    ["hecto", "Hecto", "h", 1e2],
    ["deca", "Deca", "da", 1e1],
    ["", "", "", 1],
    ["deci", "Deci", "d", 1e-1],
    ["centi", "Centi", "c", 1e-2],
    ["milli", "Milli", "m", 1e-3],
    ["micro", "Micro", "u", 1e-6],
    ["nano", "Nano", "n", 1e-9],
    ["pico", "Pico", "p", 1e-12],
    ["femto", "Femto", "f", 1e-15],
    ["atto", "Atto", "a", 1e-18],
    ["zepto", "Zepto", "z", 1e-21],
    ["yocto", "Yocto", "y", 1e-24],
    ["ronto", "Ronto", "r", 1e-27],
    ["quecto", "Quecto", "q", 1e-30]
  ];

  const seoConversions = [
    { slug: "meter-to-feet", categoryId: "length", from: "meter", to: "foot", title: "Meter to Feet", description: "Convert meters to feet with formula, examples, FAQ, and related length conversio[...]" },
    { slug: "meters-to-feet", categoryId: "length", from: "meter", to: "foot", title: "Meters to Feet", description: "Convert meters to feet with a precise formula, examples, FAQ, and related leng[...]" },
    { slug: "feet-to-meters", categoryId: "length", from: "foot", to: "meter", title: "Feet to Meters", description: "Convert feet to meters with exact international foot definitions and related l[...]" },
    { slug: "miles-to-km", categoryId: "length", from: "mile", to: "kilometer", title: "Miles to Kilometers", description: "Convert miles to kilometers with formula, examples, FAQ, and related distance [...]" },
    { slug: "km-to-miles", categoryId: "length", from: "kilometer", to: "mile", title: "Kilometers to Miles", description: "Convert kilometers to miles instantly with formula and related distance [...]" },
    { slug: "inches-to-cm", categoryId: "length", from: "inch", to: "centimeter", title: "Inches to Centimeters", description: "Convert inches to centimeters with exact formula and related length [...]" },
    { slug: "kg-to-lbs", categoryId: "weight", from: "kilogram", to: "pound", title: "kg to lbs", description: "Convert kilograms to pounds with a precise formula, FAQ, and related weight conversi[...]" },
    { slug: "lbs-to-kg", categoryId: "weight", from: "pound", to: "kilogram", title: "lbs to kg", description: "Convert pounds to kilograms with precise formula, FAQ, and related weight conversion[...]" },
    { slug: "grams-to-ounces", categoryId: "weight", from: "gram", to: "ounce", title: "Grams to Ounces", description: "Convert grams to ounces instantly with formula and related cooking or shippi[...]" },
    { slug: "celsius-to-fahrenheit", categoryId: "temperature", from: "celsius", to: "fahrenheit", title: "Celsius to Fahrenheit", description: "Convert Celsius to Fahrenheit with formula explanat[...]" },
    { slug: "fahrenheit-to-celsius", categoryId: "temperature", from: "fahrenheit", to: "celsius", title: "Fahrenheit to Celsius", description: "Convert Fahrenheit to Celsius with formula explanat[...]" },
    { slug: "liter-to-gallon", categoryId: "volume", from: "liter", to: "gallon_us", title: "Liter to Gallon", description: "Convert liters to US gallons with formula, examples, FAQ, and related v[...]" },
    { slug: "liters-to-gallons", categoryId: "volume", from: "liter", to: "gallon_us", title: "Liters to Gallons", description: "Convert liters to US gallons with a precise volume formula and rela[...]" },
    { slug: "gallons-to-liters", categoryId: "volume", from: "gallon_us", to: "liter", title: "Gallons to Liters", description: "Convert US gallons to liters with precise formula and related liqui[...]" },
    { slug: "acre-to-hectare", categoryId: "area", from: "acre", to: "hectare", title: "Acre to Hectare", description: "Convert acres to hectares for agriculture, land, mapping, and property calcu[...]" },
    { slug: "acres-to-hectares", categoryId: "area", from: "acre", to: "hectare", title: "Acres to Hectares", description: "Convert acres to hectares for agriculture, land, mapping, and property c[...]" },
    { slug: "hectares-to-acres", categoryId: "area", from: "hectare", to: "acre", title: "Hectares to Acres", description: "Convert hectares to acres with formula, examples, FAQ, and related land [...]" },
    { slug: "square-feet-to-square-meters", categoryId: "area", from: "square_foot", to: "square_meter", title: "Square Feet to Square Meters", description: "Convert square feet to square meters f[...]" },
    { slug: "mph-to-kmh", categoryId: "speed", from: "mile_per_hour", to: "kilometer_per_hour", title: "mph to km/h", description: "Convert miles per hour to kilometers per hour with formula and r[...]" },
    { slug: "psi-to-bar", categoryId: "pressure", from: "psi", to: "bar", title: "PSI to Bar", description: "Convert PSI to bar for pressure, engineering, tires, pumps, and industrial calculations[...]" },
    { slug: "gb-to-mb", categoryId: "digital", from: "gigabyte", to: "megabyte", title: "GB to MB", description: "Convert gigabytes to megabytes with decimal storage definitions, examples, FAQ, an[...]" },
    { slug: "watts-to-horsepower", categoryId: "power", from: "watt", to: "horsepower_mechanical", title: "Watts to Horsepower", description: "Convert watts to horsepower with formula and related [...]" }
  ];

  const popularConversions = [
    { name: "Kilograms to Pounds", displayName: "1 kg to lbs", category: "weight", from: "kg", to: "lb", value: "1", slug: "kg-to-lbs" },
    { name: "Celsius to Fahrenheit", displayName: "Celsius to Fahrenheit", category: "temperature", from: "c", to: "f", value: "0", slug: "celsius-to-fahrenheit" },
    { name: "Miles to Kilometers", displayName: "Miles to Kilometers", category: "length", from: "mi", to: "km", value: "1", slug: "miles-to-km" },
    { name: "Acres to Hectares", displayName: "Acres to Hectares", category: "area", from: "acre", to: "ha", value: "1", slug: "acres-to-hectares" },
    { name: "GB to MB", displayName: "GB to MB", category: "digital", from: "gb", to: "mb", value: "1", slug: "gb-to-mb" }
  ];

  const blogPosts = [
    {
      title: "How unit converters stay accurate",
      tag: "Accuracy",
      summary: "Most reliable converters normalize values through a base unit, then format the result for humans.",
      href: "unit-converter.html"
    },
    {
      title: "Metric, imperial, and US customary units",
      tag: "Global units",
      summary: "A global converter needs overlapping systems, aliases, and formula notes so users find the unit they expect.",
      href: "metric-vs-imperial.html"
    },
    {
      title: "Celsius vs Fahrenheit",
      tag: "Temperature",
      summary: "Temperature conversion uses an offset formula, so the difference between scales matters more than a simple multiplier.",
      href: "celsius-vs-fahrenheit.html"
    },
    {
      title: "How digital storage units work",
      tag: "Digital storage",
      summary: "Bits, bytes, decimal prefixes, and binary prefixes explain why storage conversions can look different across devices.",
      href: "digital-storage-units-guide.html"
    }
  ];

  const currencyFallbackRates = {
    USD: 1,
    EUR: 1.087,
    GBP: 1.27,
    CAD: 0.73,
    AUD: 0.66,
    JPY: 0.0064,
    CNY: 0.138,
    INR: 0.012,
    KES: 0.0077,
    NGN: 0.00067,
    ZAR: 0.055,
    BRL: 0.184,
    MXN: 0.055,
    CHF: 1.11,
    AED: 0.2723
  };

  const categories = applyCustomUnits(buildCategories());
  const categoryMap = new Map(categories.map((category) => [category.id, category]));
  const seoMap = new Map(seoConversions.map((item) => [item.slug, item]));

  // Try to load an external seo-registry.json (generated at build time) and merge entries into seoMap.
  // This allows the static sitemap generator and deployed static registry to be the source of truth.
  let seoRegistryLoadPromise = null;
  try {
    seoRegistryLoadPromise = fetch('/seo-registry.json', { cache: 'no-cache' })
      .then((r) => r.ok ? r.json() : [])
      .then((list) => {
        if (!Array.isArray(list)) return;
        list.forEach((entry) => {
          if (!entry || !entry.slug) return;
          const normalized = {
            slug: entry.slug,
            from: entry.from,
            to: entry.to,
            // support either 'category' (used by generator) or 'categoryId' (used in app)
            categoryId: entry.categoryId || entry.category || "",
            title: entry.title || "",
            description: entry.description || ""
          };
          seoMap.set(normalized.slug, normalized);
        });
      })
      .catch((err) => {
        // non-fatal: if the file doesn't exist on the server, the inline seoConversions remain the source
        if (window && window.console && typeof window.console.info === 'function') {
          window.console.info('[Universal Converter] seo-registry.json not found or failed to load', err && err.message ? err.message : err);
        }
      });
  } catch (e) {
    // swallow synchronous errors
  }

  let state = {
    categoryId: "length",
    fromUnitId: "meter",
    toUnitId: "foot",
    precision: clampNumber(Number(localStorage.getItem(storageKeys.precision)) || 12, 2, 15),
    notation: localStorage.getItem(storageKeys.notation) || "auto",
    lastRecordKey: ""
  };
  let historyTimer = 0;
  let historyEnabled = false;

  document.addEventListener("DOMContentLoaded", () => {
    initTheme();
    initHeroCanvas();
    initConverterApp();
    initSeoConverterPage();
    initCalculators();
    initNewsletter();
    initAdmin();
    registerServiceWorker();
    trackEvent("page_view", { title: document.title });
    if (document.body) document.body.classList.remove("is-loading");
  });

  ...

  function conversionPageUrl(slug) {
    const config = seoMap.get(slug);
    if (!config) return mainConverterUrlForConversion(slug);
    const categoryId = config.categoryId || config.category;
    return converterRouteUrl({ category: categoryId, from: config.from, to: config.to, value: "1", slug });
  }

  function mainConverterUrlForConversion(slug) {
    const config = seoMap.get(slug);
    if (config) {
      const categoryId = config.categoryId || config.category;
      return converterRouteUrl({ category: categoryId, from: config.from, to: config.to, value: "1", slug });
    }
    return "/#converter";
  }

  async function initSeoConverterPage() {
    const container = document.getElementById("seoConverter");
    if (!container) return;
    // Wait for external seo registry to load (if present) so slug resolution uses the authoritative registry
    if (seoRegistryLoadPromise) {
      try { await seoRegistryLoadPromise; } catch (e) { /* ignore */ }
    }
    const slug = getSeoSlugFromPath(container.dataset.slug || location.pathname);
    const config = seoMap.get(slug) || (
      container.dataset.category && container.dataset.from && container.dataset.to
        ? {
            categoryId: container.dataset.category,
            from: container.dataset.from,
            to: container.dataset.to
          }
        : null
    );
    const value = container.dataset.value || "1";
    if (!config) {
      window.location.replace("/#converter");
      return;
    }

    const target = converterRouteUrl({ category: config.categoryId || config.category, from: config.from, to: config.to, value, slug });
    window.location.replace(target);
  }

  ...

}());
