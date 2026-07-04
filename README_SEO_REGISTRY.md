SEO registry runtime notes

This branch adds runtime loading and normalization for an optional seo-registry.json file so the client can resolve SEO slugs to exact converter routes.

How to generate seo-registry.json (recommended)
- The repository contains a PowerShell generator (generate-conversion-pages.ps1) that creates static SEO pages. Add a step to that generator (or a separate script) to output a seo-registry.json alongside the static files. Each entry must include the fields: slug, category (or categoryId), from, to. Example entry:

  {
    "slug": "acres-to-hectares",
    "category": "area",
    "from": "acre",
    "to": "hectare",
    "title": "Acres to Hectares"
  }

- Place seo-registry.json at the site root so it's served as https://your-site.example/seo-registry.json when deployed.

How to regenerate sitemap.xml
- Run the included PowerShell script generate-sitemap.ps1 which reads seo-registry.json when present and emits sitemap.xml with /converter?category=... links for SEO pages.

Testing the deployed site
1) Deploy the site ensuring seo-registry.json and sitemap.xml are published at the site root.
2) Run the test script included here:
   chmod +x tools/test-sitemap-links.sh
   ./tools/test-sitemap-links.sh https://theuniversalconverter.com/sitemap.xml

The script prints each sitemap URL and the final URL after following redirects. It flags entries that end at the generic /#converter or whose /converter target is missing category/from/to parameters.

If you want me to open the PR with these files and the app.js changes, confirm and the PR will be created for review.
