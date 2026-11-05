# E. Deniz Gedikli — academic website

A lightweight academic website: a portrait, clear typography, short introduction, profile icons, and eight navigation links. All pages use plain HTML, CSS, and small JavaScript files. No Homebrew, Ruby, Jekyll installation, Node installation, or build command is needed.

## View it on your computer

Unzip the package and double-click `index.html`. The navigation, publication search, research-area filter, and publication-type filter also work locally. Keep the `assets` folder alongside the HTML files.

## Publish on GitHub Pages

1. Sign in to GitHub. Create a public repository named `YOUR-USERNAME.github.io`, replacing `YOUR-USERNAME` with your actual GitHub username. If you already have that repository, use it and preserve a copy of its existing files before replacing them.
2. Open the repository's **Code** tab, choose **Add file → Upload files**, and upload the contents of this folder. Include every HTML file and the whole `assets` folder. Upload the extracted files, not the ZIP itself.
3. Make sure **index.html is at the top level of the repository**, alongside `papers.html`, `research.html`, and the other pages. Do not put everything inside an extra `deniz-github-pages` folder. This is what makes GitHub display the website rather than the README.
4. Commit the files to the `main` branch.
5. Go to **Settings → Pages**. Under **Build and deployment**, select **Deploy from a branch**, choose **main**, and choose **/ (root)**. Click **Save**.
6. GitHub will display the website address in the Pages settings when the deployment is ready. It may take several minutes.

An ordinary project repository also works. Its address will include the repository name. All page and asset links are relative, so the same files work in either case. No custom domain is required.

The included `.nojekyll` file tells GitHub to publish the static files directly. Finder may hide this file; it can also be created in the GitHub file editor using **Add file → Create new file**.

Official instructions: https://docs.github.com/en/pages/quickstart

## Edit the website

| File | What to change |
| --- | --- |
| `index.html` | Name, introduction, contact icons, and homepage navigation |
| `research.html` | Research descriptions |
| `papers.html` | Combined journal articles, conference contributions, and preprints |
| `conferences.html` | Conference papers and meeting abstracts |
| `teaching.html` | Courses and teaching descriptions |
| `educational-content.html` | Learning hub |
| `marine-energy-introduction.html` | Resources, applications, and introductory calculators |
| `ocean-waves-hub-v2.html` | Regular waves, pressure, velocity, and spectral models |
| `marine-renewable-energy-devices.html` | Eleven device families and the PTO oscillator |
| `response-amplitude-operator.html` | HMEC heave and heave–pitch RAO module |
| `assets/rao-model.js`, `assets/rao-app.js`, `assets/rao.css` | Browser solver, controls, animation, and layout |
| `assets/rao/` | Original HMEC user manual (PDF) and three MATLAB source files |
| `fluid-dynamics.html` | Fluid Dynamics learning section |
| `potential-flow.html` | Potential Flow Module: sources, sinks, vortices, and doublets |
| `assets/pflow-model.js`, `assets/pflow-app.js`, `assets/pflow.css` | Potential-flow equations, interface, and styles |
| `assets/energy-models.js` | Shared scientific equations in SI units |
| `assets/education.js` | Shared plots and resource calculators |
| `assets/wave-lab.js` | Ocean Waves Lab controls and animation |
| `assets/device-atlas.js` | Device explanations, SVG diagrams, and filters |
| `assets/education.css` | Responsive teaching-page styles |
| `assets/education-sources.json` | Reference URLs used in the lessons |
| `SITE-CHECKS.md` | Review scope, numerical checks, and remaining limitations |
| `LINK-CHECKS.csv` | Outgoing link inventory and verification status |
| `lab.html` | Laboratory information |
| `book.html` | Book project |
| `cv.html` | Abbreviated CV and contact details |
| `assets/styles.css` | Colors, fonts, spacing, and responsive layout |
| `assets/site.js` | CV print button and legacy filtering support |
| `assets/publications.js` | Search, research-area and publication-type filters |
| `assets/publications.css` | Publication controls and labels |
| `assets/publications.json` | Structured snapshot of the publication metadata |
| `PUBLICATION-NOTES.md` | Reconciliation notes, sources, and records needing clarification |
| `assets/deniz-gedikli.png` | Portrait |
| `assets/flow-mesh.css` | Portrait and mesh layout |
| `assets/flow-mesh.js` | Decorative mesh animation and pause control |

To replace the photo, save a new PNG as `assets/deniz-gedikli.png`. The grayscale appearance is applied by CSS; the original image remains in color. Remove `filter:grayscale(1)` from `.portrait` to show the color version.

To add a publication, copy an existing `<article class="paper" data-topic="..." data-type="..." data-year="...">` entry into the appropriate year section in `papers.html`. For conference contributions, also add it to `conferences.html`. Topics are `viv`, `energy`, `ice`, `data`, and `structures`; publication types are `journal`, `conference`, and `preprint`. The filter updates its count automatically. Keep the structured snapshot in `assets/publications.json` in sync when editing; the HTML pages do not fetch this file.

The updated list contains 26 journal articles, 45 conference contributions, and one preprint. Papers displays all types by default. The Marine Renewable Energy filter returns 12 entries: one journal article and eleven conference contributions. Conference papers and meeting abstracts have separate visible labels. These records were reconciled from the 100 entries in the supplied Scholar export, with duplicates, theses, and ambiguous entries documented in `PUBLICATION-NOTES.md`.

### Updating an existing customized site

Replace `papers.html` and add `conferences.html`, plus `assets/publications.js`, `assets/publications.css`, and `assets/publications.json`. Add `<a href="conferences.html">Conferences</a>` after Papers in the navigation on your other pages. If your live biography, courses, or other pages have changed since the original package, preserve those edits. The full package includes the eight-item navigation on every page; its `assets/styles.css` also adjusts homepage navigation spacing for eight items.

The CV is explicitly an abbreviated HTML CV, not a copy of an official full CV. The print button opens the browser's print dialog, where visitors can select Save as PDF.

## Content sources and notes

- Professional profile: user-supplied faculty and research information, supplemented by the University of Hawaiʻi faculty directory.
- Publications: the user's Google Scholar PDF captured on November 2, 2026. Author order and listed bibliographic years are retained. The Marine Structures paper assigned to 2027 is identified by its issue year.
- Portrait: extracted from that Google Scholar PDF. A higher-resolution replacement can be added at any time.
- Every included publication links directly to its Google Scholar citation record extracted from the supplied PDF. They do not imply local access to full-text PDFs.
- Book: identified as in preparation; no release date is promised.
- Course descriptions summarize the teaching areas and do not imply a current semester schedule.

The site has no analytics, tracking cookies, account system, contact form backend, external fonts, or runtime dependencies. Contact buttons open email or the linked public profiles.

`404.html` is the optional page GitHub displays when someone visits a nonexistent address. It is separate from the homepage and does not cause a 404 error.

## Homepage mesh

The supplied flow-mesh visual is integrated beside the portrait on the homepage. It is a decorative animated mesh, not a computed fluid-flow field. It reacts to the pointer, has a Pause/Play control, respects reduced-motion settings, and stops animating while offscreen or in a hidden tab. A static SVG remains when JavaScript is unavailable.

For this homepage-only update, upload `index.html`, `assets/flow-mesh.css`, and `assets/flow-mesh.js`. Keep the existing portrait, stylesheet, scripts, and other pages in place. No build tools or external animation libraries are required.

## Educational Content update

Use **Educational Content → Marine Energy** to enter the lessons. The introduction, Ocean Waves Lab, and Device Atlas link to one another, their sources, and the relevant teaching and research pages. Upload all four new HTML pages and all new education assets, and update the navigation on your existing pages. The full package already includes those changes. Preserve any later edits you have made to a live site.

These are instructional models, with assumptions shown next to their outputs. They are not site assessments or device-design tools. Scientific references require an internet connection; the lessons and calculators themselves run locally. See `SITE-CHECKS.md` for what was reviewed and which external destinations could not be fully verified.

## Response Amplitude Operator Module

From **Educational Content → Marine Energy**, open **Response Amplitude Operator Module**. The experiment runs locally in the browser, with no MATLAB installation or external services. Start with heave, save a baseline, then change one input. Switch to heave and pitch to explore how the two motions interact. The plots show the steady response to regular waves and mean mechanical power absorbed by the PTO.

The page includes the original MATLAB source and the user and instructor manual. If you update an existing site by hand, copy the module page, its three CSS/JS assets, the entire `assets/rao/` folder, and the four updated Marine Energy navigation pages. See `RAO-CHECKS.md` for the numerical checks. The package retains the owner-supplied restored CV.


## Fluid Dynamics

This section sits alongside Marine Energy in Educational Content. Its first lesson is the Potential Flow Module. Students can add and drag sources, sinks, vortices, and doublets, adjust their strengths, play tracers, place a fixed dye emitter, and export a velocity field as CSV. Everything runs in the browser.

The solver's equations and numerical checks are described in `POTENTIAL-FLOW-CHECKS.md`. The Marine Energy pages and restored CV remain unchanged.

When updating an existing site, include `educational-content.html`, `fluid-dynamics.html`, `potential-flow.html`, and the three pflow CSS/JS assets. The route-planning page, its navigation assets, and the original-program materials have been removed from this package. Uploading new files does not delete old files in an existing repository; use the package's file list as the current site inventory. The learning section now uses `fluid-dynamics.html`.
