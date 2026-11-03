/* Decorative mesh adapted from the supplied flow-mesh demo. No flow solver. */
(() => {
  window.disposeHomeMesh?.();
  window.disposeHomeMesh = null;
  const panel = document.querySelector('[data-flow-mesh]');
  if (!panel) return;
  const canvas = panel.querySelector('canvas');
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  const button = panel.querySelector('.mesh-toggle');
  const fallback = panel.querySelector('.flow-mesh-fallback');
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  const events = new AbortController();
  let width = 0, height = 0, points = [], phase = 0, previous = 0;
  let frame = 0, paused = false, inView = true, disposed = false;
  let pointer = null;
  const canAnimate = () => !paused && !motion.matches && !document.hidden && inView && !disposed;

  function paint() {
    ctx.clearRect(0, 0, width, height);
    const positions = points.map(point => {
      let x = point.x + Math.sin(phase + point.phase + point.y * .009) * 7;
      let y = point.y + Math.cos(phase * .8 + point.phase) * 4;
      if (pointer) {
        const dx = x - pointer.x, dy = y - pointer.y, distance = Math.hypot(dx, dy);
        const push = Math.max(0, 1 - distance / 110) ** 2 * 20;
        x += dx / (distance || 1) * push;
        y += dy / (distance || 1) * push;
      }
      return { x, y };
    });
    const fadeAt = x => Math.max(0, Math.min(1, x / (width * .22), (width + 15 - x) / 45));
    const reach = Math.min(100, Math.max(65, width / 5));
    for (let i = 0; i < positions.length; i++) {
      const a = positions[i];
      for (let j = i + 1; j < positions.length; j++) {
        const b = positions[j], distance = Math.hypot(a.x - b.x, a.y - b.y);
        if (distance > reach) continue;
        const x = (a.x + b.x) / 2, y = (a.y + b.y) / 2;
        const hover = pointer ? Math.max(0, 1 - Math.hypot(x - pointer.x, y - pointer.y) / 150) : 0;
        ctx.strokeStyle = `rgba(44,111,141,${(.075 + .26 * (1 - distance / reach) + .14 * hover) * fadeAt(x)})`;
        ctx.lineWidth = .8 + hover * .35;
        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
      }
      ctx.fillStyle = `rgba(31,109,143,${.32 * fadeAt(a.x)})`;
      ctx.beginPath(); ctx.arc(a.x, a.y, 1.45, 0, Math.PI * 2); ctx.fill();
    }
  }

  function resize() {
    const box = panel.getBoundingClientRect();
    width = box.width; height = box.height;
    const dpr = Math.min(devicePixelRatio || 1, 2);
    canvas.width = Math.round(width * dpr); canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    const cols = Math.max(5, Math.ceil(width / 65) + 1), rows = 5;
    // Stable irregular spacing avoids a visual jump each time the panel resizes.
    const random = seed => { const value = Math.sin(seed * 127.1 + 311.7) * 43758.5453; return value - Math.floor(value); };
    points = [];
    for (let row = 0; row < rows; row++) for (let col = 0; col < cols; col++) {
      const seed = row * 37 + col;
      points.push({
        x: col / (cols - 1) * (width + 24) - 12 + (random(seed) - .5) * 28,
        y: row / (rows - 1) * (height + 24) - 12 + (random(seed + 301) - .5) * 24,
        phase: random(seed + 601) * Math.PI * 2
      });
    }
    paint();
  }

  function tick(time) {
    frame = 0;
    if (!canAnimate()) { previous = 0; return; }
    if (previous) phase += Math.min(time - previous, 50) * .00048;
    previous = time;
    paint();
    frame = requestAnimationFrame(tick);
  }

  function sync() {
    button.hidden = motion.matches;
    button.setAttribute('aria-label', paused ? 'Play mesh animation' : 'Pause mesh animation');
    button.querySelector('span').textContent = paused ? 'Play' : 'Pause';
    button.querySelector('[data-pause-icon]').toggleAttribute('hidden', paused);
    button.querySelector('[data-play-icon]').toggleAttribute('hidden', !paused);
    if (!canAnimate()) {
      cancelAnimationFrame(frame); frame = 0; previous = 0;
      if (motion.matches) { pointer = null; paint(); }
    } else if (!frame) frame = requestAnimationFrame(tick);
  }

  panel.addEventListener('pointermove', event => {
    if (!canAnimate()) return;
    const rect = panel.getBoundingClientRect();
    pointer = { x: event.clientX - rect.left, y: event.clientY - rect.top };
  }, { signal: events.signal, passive: true });
  const clearPointer = () => { pointer = null; if (!canAnimate()) paint(); };
  panel.addEventListener('pointerleave', clearPointer, { signal: events.signal });
  panel.addEventListener('pointercancel', clearPointer, { signal: events.signal });
  panel.addEventListener('pointerup', event => { if (event.pointerType !== 'mouse') clearPointer(); }, { signal: events.signal });
  button.addEventListener('click', () => { paused = !paused; pointer = null; paint(); sync(); }, { signal: events.signal });
  document.addEventListener('visibilitychange', sync, { signal: events.signal });
  motion.addEventListener('change', sync);
  const observer = new ResizeObserver(resize);
  observer.observe(panel);
  const visibility = new IntersectionObserver(entries => { inView = entries[0].isIntersecting; sync(); });
  visibility.observe(panel);
  window.disposeHomeMesh = () => {
    disposed = true; cancelAnimationFrame(frame); events.abort();
    observer.disconnect(); visibility.disconnect(); motion.removeEventListener('change', sync);
  };
  canvas.hidden = false;
  fallback.setAttribute('hidden', '');
  resize(); sync();
})();
