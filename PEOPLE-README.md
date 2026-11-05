# People page — FSI–NLD Laboratory

Created November 4, 2026. This package updates the latest retrieved website archive; it does not change a live website or GitHub repository.

## Publish

Copy the contents of the `deniz-github-pages` folder into the existing website's publishing root. Keep the folder structure for `assets/`. Commit the changed/new files using your existing deployment workflow. Do not put the whole folder inside another identically named folder.

The dedicated page is `people.html`. People is linked from the homepage and every existing main navigation menu. The Lab page includes links to the group, graduate alumni, and research enquiries. Existing page content and educational modules are retained; their navigation now includes People.

The separately supplied `people-preview.html` is a self-contained preview of the website that opens on People. It is for convenient review, not a replacement for the normal website files. Its internal links use hash navigation, whereas the deployed site uses separate HTML files.

## What is included

- Current researchers: principal investigator, one current postdoc, five Ph.D. students, and one M.S. student.
- Graduate alumni: five completed M.S. records, distinguishing thesis and Plan B projects.
- Former postdoctoral researchers: Emad Makki and Hongtao Li.
- Undergraduate research alumni: Adiva K. Udui and Kayla Crook.
- Clara Encke's completed M.S. degree links to her current Ph.D. profile.
- Virginia Groeschel is explicitly marked as co-advised, with Oceana Francis as main advisor.
- A dated laboratory group photo, name/topic/degree search, responsive cards, keyboard-accessible controls, and a contact section.

## Source and editorial decisions

Research topics, completed degrees, and mentoring relationships come from section 4.2.2, pages 6–8 of the supplied Statement of Endeavors. The group image was extracted from the same document; its caption on page 14 dates it to the SOEST Open House on October 21, 2023. It is labeled as an archival image, not as a current team photograph.

The owner's explicit November 4, 2026 updates take precedence: Meysam Rajabi is a Ph.D. student; Ozgur Demir is the current postdoc; Emad Makki and Hongtao Li are former postdocs. Hongtao's former-postdoc classification follows that update; the older statement's 2020 remote-research interval is not presented as a confirmed postdoctoral appointment period.

Other current memberships and topics follow the supplied mentoring record, not an independent current-status check. Anticipated graduation dates, unconfirmed alumni employers, private contacts, and unsupported personal-profile links are omitted. Committee-only students and prospective applicants are not included in the lab roster. The source statement itself is not distributed in this package.

## Update names, topics, status, or portraits

The source of truth for this page is `assets/people.json`. Edit the relevant record, update its `role` or move it between the appropriate arrays, and update the `updated` field. Then regenerate the static HTML with:

```sh
python3 tools/build_people.py
```

The helper uses only the Python standard library. Commit both the edited JSON and regenerated `people.html`. Editing JSON alone does not update the deployed static page.

Portraits are optional. With each person's permission, place a portrait inside `assets/people/` and set the record's `photo` to its relative path, for example `assets/people/meysam-rajabi.jpg`. Leave `photo` as an empty string to keep the initials avatar. Then regenerate the page. Do not publish a photograph without permission. No stock or AI-generated individual portraits have been used.

The layout is defined in `templates/people.template.html` and `assets/people.css`. Interactive search is in `assets/people.js`. All profiles and degree records are present in static HTML and remain readable with JavaScript disabled. Search is a progressive enhancement; no server, external library, or API is required at runtime.

## Checks

See `PEOPLE-CHECKS.md` for the checks performed. Existing website modules were preserved, not revalidated as part of this roster update.
