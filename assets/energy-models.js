/* Shared educational equations; SI units throughout. */
(function (root) {
  const g = 9.81, rho = 1025, tau = 2 * Math.PI;
  function wavenumber(T, h) {
    if (!(T > 0 && h > 0)) throw new RangeError('Period and depth must be positive.');
    const omega = tau / T; let lo = 0, hi = Math.max(omega * omega / g, 1e-8);
    while (g * hi * Math.tanh(hi * h) < omega * omega) hi *= 2;
    for (let i = 0; i < 75; i++) { const mid = (lo + hi) / 2; if (g * mid * Math.tanh(mid * h) < omega * omega) lo = mid; else hi = mid; }
    return (lo + hi) / 2;
  }
  function wave(H, T, h) {
    const k = wavenumber(T, h), omega = tau / T, L = tau / k, kh = k * h;
    const n = .5 * (1 + (2 * kh > 50 ? 0 : 2 * kh / Math.sinh(2 * kh)));
    const c = omega / k, cg = n * c, E = rho * g * H * H / 8;
    const ka = k * H / 2, relativeAmplitude = H / (2 * h), breakingHeight = .142 * L * Math.tanh(kh);
    const breaking = H >= breakingHeight, caution = ka > .1 || relativeAmplitude > .1;
    return { H, T, h, k, omega, w: omega, L, kh, c, cg, E, P: E * cg, a: H / 2, ka, relativeAmplitude, breakingHeight, breaking, caution };
  }
  function validity(q) {
    if (q.breaking) return 'This setting exceeds the Miche estimate for a nonbreaking wave. Reduce the height or change the period and depth; the linear-wave power result is hidden.';
    if (q.caution) return 'Use this result cautiously: ka or a/h exceeds 0.1. These are conservative teaching checks, not universal limits. Nonlinear effects may matter.';
    return 'This setting passes our basic small-amplitude teaching checks. That is a screening check, not validation for a real site.';
  }
  function current(U, D, Cp) { const A = Math.PI * D * D / 4, incident = .5 * rho * A * U ** 3; return { A, incident, power: incident * Cp }; }
  function carnot(warm, cold) { return 1 - (cold + 273.15) / (warm + 273.15); }
  function pto(forceKN, ratio, dampingRatio) {
    const mass = 10000, wn = 1, omega = ratio * wn, stiffness = mass * wn ** 2;
    const ptoDamping = 2 * mass * wn * dampingRatio, damping = 2 * mass * wn * .05 + ptoDamping;
    const amplitude = forceKN * 1000 / Math.hypot(stiffness - mass * omega ** 2, damping * omega);
    return { amplitude, power: .5 * ptoDamping * omega ** 2 * amplitude ** 2, omega, damping };
  }
  function hyperbolicRatio(v, kh, cosine) {
    if (kh > 35) return Math.exp(v - kh) * (1 + (cosine ? 1 : -1) * Math.exp(-2 * v)) / (1 - Math.exp(-2 * kh));
    return (cosine ? Math.cosh(v) : Math.sinh(v)) / Math.sinh(kh);
  }
  function sample(q, z, t, x = 0) {
    const theta = q.k * x - q.omega * t, v = q.k * (z + q.h);
    const ch = hyperbolicRatio(v, q.kh, true), sh = hyperbolicRatio(v, q.kh, false);
    const pf = q.kh > 35 ? Math.exp(q.k * z) * (1 + Math.exp(-2 * v)) / (1 + Math.exp(-2 * q.kh)) : Math.cosh(v) / Math.cosh(q.kh);
    return { eta: q.a * Math.cos(theta), u: q.a * q.omega * ch * Math.cos(theta), w: q.a * q.omega * sh * Math.sin(theta), p: rho * g * q.a * pf * Math.cos(theta), dx: -q.a * ch * Math.sin(theta), dz: q.a * sh * Math.cos(theta) };
  }
  function spectrum(Hm0, Tp, h, N = 400) {
    const fp = 1 / Tp, fmin = fp / 5, fmax = fp * 5, df = (fmax - fmin) / N;
    const raw = []; let sum = 0, seed = 81237;
    for (let i = 0; i < N; i++) { const f = fmin + (i + .5) * df, shape = f ** -5 * Math.exp(-1.25 * (fp / f) ** 4); raw.push({ f, shape }); sum += shape * df; }
    const m0 = Hm0 ** 2 / 16; let flux = 0, inverseMoment = 0;
    const components = raw.map(({ f, shape }) => {
      const S = shape * m0 / sum, cg = wave(0, 1 / f, h).cg;
      flux += rho * g * S * df * cg; inverseMoment += S * df / f;
      seed = (1664525 * seed + 1013904223) >>> 0;
      return { f, S, amplitude: Math.sqrt(2 * S * df), phase: tau * seed / 4294967296 };
    });
    return { components, m0, flux, Te: inverseMoment / m0, fp, fmin, fmax, df };
  }
  const api = { g, rho, tau, wavenumber, wave, validity, current, carnot, pto, sample, spectrum, hyperbolicRatio };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.MarineModels = api;
})(typeof window !== 'undefined' ? window : globalThis);
