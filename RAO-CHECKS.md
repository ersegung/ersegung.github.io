# HMEC Response Amplitude Operator Module

The lesson adapts Dr. E. D. Gedikli’s HMEC RAO Demonstration Suite, v1.0. The three original MATLAB files and the PDF manual are included unchanged. The interactive page runs JavaScript and needs no external services.

## Numerical comparison

Compared both browser solvers with a separate NumPy/SciPy implementation of the supplied equations. The 22 cases exercise mass, restoring stiffness, damping, wave amplitude, coupling, pitch moment, geometry, forcing, and the endpoints of the sweeps. The 546 reference comparisons cover real and imaginary responses, magnitude, phase, physical motion, mechanical power, wave number, sweep peaks, and diagonal inertia–restoring balance periods. For selected-period readouts, real and imaginary responses and power curves are interpolated separately with PCHIP, as in the MATLAB source. Direct evaluations were checked separately. The largest scaled difference (absolute difference divided by max(1, absolute reference value)) was below 3 × 10⁻¹⁵.

| Default at T = 7 s and wave amplitude a = 0.5 m | Heave only | Coupled heave and pitch |
| --- | ---: | ---: |
| Mean mechanical PTO power | 14.0345 kW | 54.4467 kW |
| Heave peak period on the sweep | 6.6667 s | 6.6977 s |
| Pitch peak period on the sweep | — | 6.3488 s |

The page also offers 11 repeatable checks, including quadratic power scaling with amplitude and zero pitch when both coupling and direct pitch excitation are removed. With finite coupling, pitch can remain nonzero when the direct pitch moment is switched off. Phase is undefined at zero response. An identically zero response has no unique peak period.

These checks concern numerical agreement with the teaching models. The coefficients are synthetic, and the results do not validate or predict the output of a specific device.
