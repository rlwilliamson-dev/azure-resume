// counter.js — fetches and animates the visitor count
(() => {
  const API_URL = "/api/counter";   // proxied by Static Web Apps to the Function
  const TIMEOUT_MS = 4000;
  const el = document.getElementById("visitor-count");

  if (!el) {
    console.warn("counter.js: #visitor-count element not found");
    return;
  }

  // Animate from current shown value up to the new value.
  function animateTo(target) {
    const start = 0;
    const duration = 800;
    const startTime = performance.now();

    function tick(now) {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      // ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.floor(start + (target - start) * eased).toLocaleString();
      if (progress < 1) requestAnimationFrame(tick);
      else el.textContent = target.toLocaleString();
    }
    requestAnimationFrame(tick);
  }

  async function fetchWithTimeout(url, options = {}, timeout = TIMEOUT_MS) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeout);
    try {
      return await fetch(url, { ...options, signal: controller.signal });
    } finally {
      clearTimeout(timer);
    }
  }

  async function updateCounter() {
    try {
      const res = await fetchWithTimeout(API_URL, { method: "POST" });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      if (typeof data.count !== "number") throw new Error("Bad payload");
      animateTo(data.count);
    } catch (err) {
      console.error("counter.js:", err);
      el.textContent = "—";
      el.title = "Counter temporarily unavailable";
    }
  }

  updateCounter();
})();