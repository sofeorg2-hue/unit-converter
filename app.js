diff --git a/app.js b/app.js
index d78efe3..03a5c74 100644
--- a/app.js
+++ b/app.js
@@
   function initSeoConverterPage() {
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
-      window.location.replace("/#converter");
+      // Diagnostic: log unresolved slug so maintainers can find missing registry entries
+      if (window && window.console && typeof window.console.warn === 'function') {
+        window.console.warn(`[Universal Converter] SEO slug could not be resolved: "${slug}" - redirecting to generic converter`);
+      }
+      window.location.replace("/#converter");
       return;
     }
@@
-    const target = converterRouteUrl({ category: config.categoryId || config.category, from: config.from, to: config.to, value, slug });
+    const categoryId = config.categoryId || config.category;
+    // Diagnostic: if slug resolves but category or units are missing, log details
+    if (!categoryId || !config.from || !config.to) {
+      if (window && window.console && typeof window.console.warn === 'function') {
+        window.console.warn('[Universal Converter] SEO config incomplete for slug:', slug, config);
+      }
+    }
+    const target = converterRouteUrl({ category: categoryId, from: config.from, to: config.to, value, slug });
     window.location.replace(target);
   }
+
