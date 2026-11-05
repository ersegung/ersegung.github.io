# Potential Flow Module checks

The solver appears under Educational Content → Fluid Dynamics. The equations and interactions are retained from the verified solver.

## Numerical checks

264 numerical comparisons checked the five elementary velocity fields, divergence and curl away from singularities, velocities recovered from the streamfunction, and zero normal velocity on a cylinder with and without centred circulation. A point-vortex tracer completed an orbit with a position error below 5 × 10⁻⁹ model length units. Streamfunction variation along a cylinder streamline was below 4 × 10⁻⁹. Eight built-in checks remain available on the page.

Coordinates use x to the right and y upward. Positive circulation is counterclockwise. Lengths and time are illustrative model units. Default source/sink flux and vortex circulation magnitudes are 5π; the doublet coefficient in φ = DX/r² is 6.25. Default uniform speed is 1.

Streamlines use fourth-order Runge–Kutta integration in arclength. Tracers use RK4 in model time with speed-dependent substeps. The velocity formulas are not clipped; arrow lengths are capped for readability. Integration stops within 0.13 units of a singularity or inside an analytically identified cylinder. The cylinder boundary is shown only for one positive doublet aligned with a nonzero uniform stream, with optional concentric vortices. Editing the flow clears tracer history.

## Scope

This is an ideal incompressible and irrotational-flow lesson away from singularities. It does not solve viscosity, separation, vortex shedding, surface waves, or structural dynamics. References to MIT and Oregon State University's potential-flow teaching material remain on the page.
