# Fix SEO registry runtime

This change makes the client-side application more robust when resolving SEO slugs and ensures the sitemap-generated SEO routes open the exact converter route instead of falling back to the generic converter.

What changed

- app.js
  - Loads /seo-registry.json at runtime (if present) and merges entries into the in-memory seoMap.
  - Tolerates either `category` or `categoryId` fields in registry entries.
  - initSeoConverterPage awaits the optional registry load so slug resolution uses the authoritative registry when available.

- tools/test-sitemap-links.sh
  - Bash script to fetch sitemap.xml, follow redirects, and flag sitemap entries that land on the generic converter or have missing category/from/to parameters.

- seo-registry.sample.json
  - Example registry entries and format for your build process to output.

- README_SEO_REGISTRY.md
  - Notes describing the build-time generation of seo-registry.json, sitemap regeneration, and how to run the tester.

Why this helps

- The sitemap generator uses seo-registry.json to produce SEO routes at build time. If the deployed site doesn't serve that registry to the client, client-side slug-to-route resolution can fail and cause links to open a generic converter instead of the intended category/unit conversion. Loading and merging the registry at runtime fixes this mismatch.

Testing

1. Generate and deploy seo-registry.json to the site root.
2. Run the powershell sitemap generator to update sitemap.xml.
3. Deploy and run tools/test-sitemap-links.sh against the deployed sitemap.xml.

