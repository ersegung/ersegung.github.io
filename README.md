# E. Deniz Gedikli — academic website

This is my academic website which includes: a portrait, clear typography, short introduction, profile icons, and seven navigation buttons. All pages use plain HTML, CSS, and small JavaScript files. No Homebrew, Ruby, Jekyll installation, Node installation, or build command is needed.

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

To replace the photo, save a new PNG as `assets/deniz-gedikli.png`. The grayscale appearance is applied by CSS; the original image remains in color. Remove `filter:grayscale(1)` from `.portrait` to show the color version.

To add a publication, copy an existing `<article class="paper" data-topic="..." data-type="..." data-year="...">` entry into the appropriate year section in `papers.html`. For conference contributions, also add it to `conferences.html`. Topics are `viv`, `energy`, `ice`, `data`, and `structures`; publication types are `journal`, `conference`, and `preprint`. The filter updates its count automatically. Keep the structured snapshot in `assets/publications.json` in sync when editing; the HTML pages do not fetch this file.

The updated list contains 25 journal articles, 45 conference contributions, and two preprints. Papers displays all types by default. The Marine Renewable Energy filter returns 12 entries: one journal article and eleven conference contributions. Conference papers and meeting abstracts have separate visible labels. These records were reconciled from the 100 entries in the supplied Scholar export, with duplicates, theses, and ambiguous entries documented in `PUBLICATION-NOTES.md`.

### Updating an existing customized site

Replace `papers.html` and add `conferences.html`, plus `assets/publications.js`, `assets/publications.css`, and `assets/publications.json`. Add `<a href="conferences.html">Conferences</a>` after Papers in the navigation on your other pages. If your live biography, courses, or other pages have changed since the original package, preserve those edits. The full package includes the seven-item navigation on every page; its `assets/styles.css` also adjusts homepage navigation spacing for seven items.

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
