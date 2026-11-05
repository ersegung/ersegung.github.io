# People page checks

Checks performed November 4, 2026.

- Roster: 8 current profiles (including the PI), 5 completed M.S. records, 2 former postdocs, and 2 undergraduate alumni. Clara's M.S. record is a degree history, not an additional current person.
- Confirmed requested corrections: Meysam is Ph.D.; Ozgur is current postdoc; Hongtao and Emad are former postdocs.
- Browser checks used Chromium with an in-memory, fully inlined page and the self-contained preview. Direct file/localhost navigation was blocked by the environment, so deployed HTTP access was not tested.
- Name search, empty state, clear/reset, details disclosure, search-clearing section links, and Clara's current-profile link passed.
- Preview home-to-People and Lab-to-People navigation passed.
- All 17 profile/degree entries remain visible without JavaScript; inactive search controls are hidden.
- No JavaScript errors were observed during tested People workflows.
- No horizontal overflow at 320, 375, 390, 768, 1024, and 1440 pixels.
- Group image and PI portrait loaded. Desktop and mobile screenshots visually inspected.
- HTML duplicate IDs and local file/fragment references statically checked. No missing local targets or broken fragment links were found on People.
- The roster generator ran successfully and output contains no unresolved template placeholders.
- No live repository or website was modified. Other learning modules were retained, not scientifically revalidated.
