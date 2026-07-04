(function () {
  "use strict";

  var config = window.UC_ADSENSE || {};
  var publisherId = config.publisherId || (typeof ADSENSE_ID !== "undefined" ? ADSENSE_ID : "");
  var enabled = Boolean(config.enabled || (typeof ADSENSE_ENABLED !== "undefined" && ADSENSE_ENABLED));
  var placeholder = !publisherId || publisherId === "ca-pub-XXXXXXXXXXXX";
  var slots = config.slots || {};

  document.querySelectorAll("[data-ad-placement]").forEach(function (slot) {
    slot.classList.add("adsense-placeholder");
    slot.setAttribute("data-ad-status", placeholder || !enabled ? "placeholder" : "ready");
    if (!slot.textContent.trim()) slot.textContent = "Advertisement";
  });

  if (!enabled || placeholder) return;

  if (!document.querySelector('script[src*="pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"]')) {
    var script = document.createElement("script");
    script.async = true;
    script.crossOrigin = "anonymous";
    script.src = "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=" + encodeURIComponent(publisherId);
    document.head.appendChild(script);
  }

  function createResponsiveAd(adSlot) {
    var ins = document.createElement("ins");
    ins.className = "adsbygoogle";
    ins.style.display = "block";
    ins.setAttribute("data-ad-client", publisherId);
    ins.setAttribute("data-ad-slot", adSlot);
    ins.setAttribute("data-ad-format", "auto");
    ins.setAttribute("data-full-width-responsive", "true");
    return ins;
  }

  document.querySelectorAll("[data-ad-placement]").forEach(function (slot) {
    var placement = slot.getAttribute("data-ad-placement");
    var adSlot = slots[placement];
    if (!adSlot || adSlot.indexOf("_SLOT_ID") !== -1) return;
    slot.innerHTML = "";
    slot.appendChild(createResponsiveAd(adSlot));
    window.adsbygoogle = window.adsbygoogle || [];
    window.adsbygoogle.push({});
  });
})();
