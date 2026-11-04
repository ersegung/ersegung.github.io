# Website and science review

Original review: November 3, 2026 (UTC).

**November 4 update:** Marine Energy now includes a fourth lesson, the Response Amplitude Operator Module. All 317 local links, fragment links, and asset references on the 14 site pages resolve. The owner’s earlier CV is restored verbatim; the earlier review below describes the November 3 version. See `RAO-CHECKS.md` for the new module.

## What changed

Educational Content is now a main navigation destination. Its Marine Energy section contains the introduction, Ocean Waves Lab, and Device Atlas. All three lessons link to one another and to scientific references. Teaching and Research also link into the lessons.

The attached introduction was rewritten in a conversational style. Two pages it linked to were recovered and integrated, so those paths no longer lead to absent files. Their styling now matches the academic site. Existing publication titles and author lists remain bibliographic records rather than conversational rewrites.

The original wave page referenced undefined PI and TAU constants, which interrupted its calculations. The revised pages use one shared equation module and separate interface scripts. The standalone preview embeds the same pages, styles, and scripts, including working same-page reference links.

## Scientific corrections and scope

- Regular wave height H and spectral significant height Hm₀ are separate inputs. The regular-wave energy density is ρgH²/8; the irregular-wave mean energy density is ρgHm₀²/16.
- Finite-depth dispersion and group velocity are used. The regular-wave calculator hides power beyond the Miche screening estimate. The ka and a/h checks at 0.1 are explicitly conservative teaching choices, not universal validity boundaries.
- Pressure is the wave-induced dynamic contribution. Pressure head and surface elevation share units of metres; velocities have a separate axis. The probe location is fixed at x = 0, and the mean-surface pressure value is identified as linearized.
- The spectrum uses 400 midpoint bins over 0.2fp–5fp, normalized so m₀ = Hm₀²/16. Flux integrates the group velocity of each component. The time step is at most one eighth of the shortest retained period. The 120-second synthetic record is not a measured sea state.
- The regular-wave breaking estimate is not presented as an exact limit on Hm₀. Irregular-sea warnings identify possible nonlinearity and breaking without implying the linear model simulates either.
- Current output is mechanical rotor power. A fixed Cp and a uniform unconfined flow do not represent a complete turbine power curve or net electrical output.
- OTEC uses kelvin temperatures for the Carnot ceiling. A roughly 20°C temperature difference is a site-screening guideline, not a thermodynamic threshold or a plant-efficiency claim.
- PRO and RED are distinguished: PRO uses water permeation and a pressurized stream; RED uses ion transport and an electrical circuit. The RED diagram has no hydraulic turbine.
- The PTO model is a prescribed-force linear oscillator with stated mass, frequency, and damping. It illustrates energy extraction by a damper and is not a full hydrodynamic device model.
- Eleven device families include tidal range. Code-native mechanism diagrams replace illustrations whose geometry could mislead readers. Diagram dimensions, rotor symbols, motion, and timing are explicitly schematic.
- Technology-readiness ranges are dated to the European Commission/JRC summary updated May 21, 2026. The ranges describe sectors, not a universal score for each device archetype. TRL alone does not establish cost or commercial reliability.
- Environmental statements are conditional on the device, site, and deployment scale. Small-project evidence is not treated as a blanket conclusion for large arrays.

These checks support the instructional explanations and formulas. They do not certify a design, validate a site, or guarantee that every external project/status statement remains current. The assumptions remain visible beside the models.

## Numerical checks

The calculations were compared with independent benchmark values, limiting cases, and kinematic identities. There were 68 numerical comparisons plus 27 combinations of height, period, and depth spanning the controls. All passed. The maximum relative difference in spectral flux between 400 and 8,000 bins over the same finite band was approximately 7.24 × 10⁻⁹ for the tested settings; this checks numerical integration, not the suitability of the spectrum for a real site.

| Check | Result |
| --- | --- |
| Regular wave: H = 2 m, T = 8 s, h = 50 m | L = 99.56148 m; Cg = 6.36526 m/s; P = 32.00213 kW/m |
| Deep regular wave: H = 2 m, T = 8 s, h = 200 m | P = 31.39872 kW/m |
| Current: U = 2 m/s, D = 10 m, Cp = 0.4 | Rotor power = 128.80530 kW |
| Current at zero speed | Rotor power = 0 |
| Carnot limit: warm 27°C, cold 5°C | 7.32967% |
| PTO: F₀ = 25 kN, frequency ratio 1, PTO damping ratio 0.25 | Mean extracted damper power = 43.40278 kW |
| Regular wave: H = 5 m, T = 3 s, h = 5 m | Exceeds Miche estimate; the normal power display is hidden |
| Probe: H = 1.5 m, T = 8 s, h = 50 m, z = −25 m | Horizontal amplitude 0.12702 m/s; dynamic pressure amplitude 1.62031 kPa |
| Impermeable seabed | Vertical velocity is zero |
| Default finite-band spectrum: Hm₀ = 1.5 m, Tp = 8 s, h = 50 m | m₀ = 0.140625 m²; flux = 7.78350 kW/m; Te = 6.86895 s |

## Pages, links, and controls

The local crawl covered all 13 HTML pages, their linked assets, and section fragments. It found no missing targets or duplicate IDs. The crawl checked 282 local page, asset, and fragment references. Reference anchors generated in the Device Atlas were also matched to that page's source list.

All 13 pages rendered at a 390-pixel iframe width (375-pixel content width with the browser scrollbar). The four educational pages also rendered at a 320-pixel iframe width (305-pixel content width). No page-level horizontal overflow was found. Wide reference tables scroll within their own containers.

Browser checks covered the main navigation, lesson cross-links, source-section links, three resource calculators, reset controls, invalid-wave handling, five wave-concept tabs, the seabed probe, spectral controls, animation pause, all eleven device detail views, six resource filters, and the PTO calculator. The same core navigation and models were checked in the self-contained preview. The Papers marine-energy filter returns 12 records; the Conferences filter returns 11. Search, empty states, and reset work. The deleted 2018 aquaculture contribution remains absent. The static conference count was corrected to 45.

No application-origin JavaScript errors were observed during these checks. The browser environment emitted extension metadata errors unrelated to the website. Email and telephone links have valid URI formats; no email was sent and no call was placed. The CV button invokes the existing browser print action; no PDF was saved as part of this review.

## External-link limits

`LINK-CHECKS.csv` inventories all 96 unique external URLs found in the HTML. It distinguishes readable destinations, indexed evidence with incomplete direct retrieval, and links whose live contents could not be confirmed. A restricted or timed-out retrieval is not proof that the destination is broken for visitors.

The 73 Scholar URLs consist of a profile and 72 citation records. Their owner and citation-ID structure were checked against the existing exported metadata. Scholar returned a forbidden response for the profile in this review; the individual records were not all live-opened after that restriction. LinkedIn also refused retrieval. Their destination content therefore remains unverified.

The UH home, department, and faculty URLs were found in official-site search results, but direct retrieval timed out or returned a gateway error. The PubMed original-research abstract was available through search, while direct extraction was limited. The Marine Energy Atlas landing page loaded in the browser; this review does not audit all map datasets or every interaction in that separate application.

## Existing CV and personal content

The official UH faculty search result lists Associate Professor, a 2009 bachelor's degree, and POST 403B. The SOEST directory independently lists POST 403B. The draft's 2010 degree year and POST 413E room were updated to match those institutional records. Precise promotion dates were not established, so the current appointment is labeled as current and the earlier assistant appointment as starting in 2020. The university's own experience paragraph still says Assistant Professor (2020–present), so it is not a reliable source for the promotion date.

Sources: [UH faculty profile](https://www.soest.hawaii.edu/ore/people/faculty/deniz-gedikli/), [faculty directory](https://www.soest.hawaii.edu/ore/people/faculty/), and [SOEST directory](https://www.soest.hawaii.edu/soestwp/about/directory/ersegun-deniz-gedikli/). These are institutional listings; the owner's records should settle any conflict. The book's preparation status, laboratory room assignments, and remaining personal roles were retained from the existing site rather than independently certified by this marine-energy literature review. Publication metadata retains the scope and caveats in `PUBLICATION-NOTES.md`.

## Scientific references

- [DOE: Marine Energy Basics](https://www.energy.gov/cmei/water/marine-energy-basics)
- [DOE: Resource Assessment and Characterization](https://www.energy.gov/cmei/water/marine-energy-resource-assessment-and-characterization)
- [DOE: Marine Energy Glossary](https://www.energy.gov/cmei/water/marine-energy-glossary)
- [EMEC: Wave Devices](https://www.emec.org.uk/marine-energy/wave-devices/)
- [Akylas & Mei, MIT: Dispersion of Surface Water Waves (PDF)](https://web.mit.edu/fluids-modules/waves/www/material/chap-3.pdf)
- [OpenFAST/HydroDyn: Wave Kinematics, Spectral Synthesis and Breaking Criterion (PDF)](https://openfast.readthedocs.io/en/main/_downloads/42a2cfdae2d2df1d36eae686d87eb12d/WAVE2_document.pdf)
- [DOE: Fluid-power equation and ideal actuator-disc limit (wind guide; this lab uses seawater density)](https://www.energy.gov/cmei/systems/windexchange/small-wind-guidebook)
- [EIA: Ocean Thermal Energy Conversion](https://www.eia.gov/energyexplained/hydropower/ocean-thermal-energy-conversion.php)
- [MIT: The Carnot Limit](https://news.mit.edu/2010/explained-carnot-0519)
- [Yip & Elimelech (2014): Comparison of PRO and RED, original research abstract](https://pubmed.ncbi.nlm.nih.gov/25157687/)
- [EIA: Tidal Power — turbine and barrage principles](https://www.eia.gov/energyexplained/hydropower/tidal-power.php)
- [PNNL: Findings from the 2024 OES Environmental State of the Science Report](https://www.pnnl.gov/publications/new-report-provides-update-environmental-effects-marine-renewable-energy)
- [PNNL: Ocean Engineering Basics](https://www.pnnl.gov/ocean-engineering-basics)
- [EMEC: Technology Readiness Levels](https://www.emec.org.uk/services/provision-of-wave-and-tidal-testing/pathway-to-emec/technology-readiness-levels/)
- [European Commission/JRC: Marine Renewable Energy (updated May 21, 2026)](https://blue-economy-observatory.ec.europa.eu/eu-blue-economy-sectors/marine-renewable-energy_en)
- [IEA-OES: Annual Report 2025, published 2026 (PDF)](https://tethys.pnnl.gov/sites/default/files/publications/oes-annual-report-2025.pdf)
- [NLR: Marine Energy Atlas — interactive resource maps](https://maps.nlr.gov/marine-energy-atlas/)
- [Kilcher, Fogarty & Lawson (2021): Marine Energy in the United States (PDF)](https://docs.nlr.gov/docs/fy21osti/78773.pdf)
