#!/usr/bin/env python3
"""Build people.html from assets/people.json. Python 3.9+; standard library only.

Run from any directory: python3 tools/build_people.py
The result is static HTML. JavaScript only enhances search and photo fallbacks.
"""
from pathlib import Path
import html
import json
import re
import sys
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]

def esc(value):
    return html.escape(str(value), quote=True)

def safe_url(value):
    value = str(value).strip()
    if urlparse(value).scheme not in ('', 'https', 'http', 'mailto'):
        raise ValueError(f'Unsupported link scheme: {value}')
    return esc(value)

def profile_card(person, leadership=False):
    pid, name = person['id'], person['name']
    initials = person.get('initials', '')
    photo = person.get('photo', '')
    if photo:
        avatar = (f'<div class="person-avatar" data-initials="{esc(initials)}">'
                  f'<img src="{safe_url(photo)}" alt="{esc(name)}" loading="lazy" width="80" height="80"></div>')
    else:
        avatar = f'<div class="person-avatar" aria-hidden="true">{esc(initials)}</div>'
    tag_html = ''.join(f'<span class="person-tag">{esc(topic)}</span>' for topic in person.get('topics', []))
    tags = f'<div class="person-topics">{tag_html}</div>' if tag_html else ''
    advising = f'<p class="person-advising">{esc(person["advising"])}</p>' if person.get('advising') else ''
    detail = (f'<details class="person-detail"><summary>{esc(person["detail_title"])}</summary>'
              f'<p>{esc(person["detail"])}</p></details>') if person.get('detail') else ''
    links = ''.join(f'<a href="{safe_url(link["url"])}">{esc(link["label"])}</a>' for link in person.get('links', []))
    links = f'<div class="person-links">{links}</div>' if links else ''
    cls = 'person-card person-leadership' if leadership else 'person-card'
    return f'''<article id="{esc(pid)}" class="{cls}" data-person-entry aria-labelledby="{esc(pid)}-name">
<div class="person-top">{avatar}<div><p class="person-role">{esc(person['role'])}</p><h3 class="person-name" id="{esc(pid)}-name">{esc(name)}</h3></div></div>
<p class="person-position">{esc(person.get('position', ''))}</p>
<p class="person-summary">{esc(person['summary'])}</p>{tags}{advising}{detail}{links}</article>'''

def alumni_row(person):
    continuing = ''
    if person.get('current_profile'):
        continuing = (f'<p class="person-continuing"><a href="#{esc(person["current_profile"])}" data-current-profile>'
                      f'{esc(person["current_note"])} →</a></p>')
    return f'''<article class="person-alumni" id="{esc(person['id'])}" data-person-entry aria-labelledby="{esc(person['id'])}-name">
<div class="person-alumni-date">{esc(person['date'])}<span>{esc(person['degree'])} · ORE</span></div>
<div><h3 id="{esc(person['id'])}-name">{esc(person['name'])}</h3><p class="person-alumni-title"><span>{esc(person['work_type'])}</span>{esc(person['title'])}</p>{continuing}</div></article>'''

def build():
    data = json.loads((ROOT / 'assets/people.json').read_text(encoding='utf-8'))
    all_entries = sum((data[group] for group in ['current', 'masters', 'former_postdocs', 'undergraduate_alumni']), [])
    ids = [p['id'] for p in all_entries]
    if len(ids) != len(set(ids)):
        raise ValueError('Each record must have a unique id.')
    if any(not re.fullmatch(r'[a-z][a-z0-9-]*', pid) for pid in ids):
        raise ValueError('Use lowercase letters, digits, and hyphens for ids.')
    for p in all_entries:
        for key in ('id', 'name'):
            if not p.get(key):
                raise ValueError(f'Missing required key: {key}')
        photo = p.get('photo')
        if photo and not urlparse(photo).scheme and not (ROOT/photo).is_file():
            raise ValueError(f'Missing local portrait: {photo}')
    current_ids = {p['id'] for p in data['current']}
    for p in data['masters']:
        if p.get('current_profile') and p['current_profile'] not in current_ids:
            raise ValueError(f'Unknown current profile: {p["current_profile"]}')
    phd = sum('Ph.D.' in p['role'] for p in data['current'])
    ms = sum('M.S.' in p['role'] for p in data['current'])
    postdocs = sum('Postdoctoral' in p['role'] for p in data['current'])
    replacements = {
        'CURRENT_COUNTS': f'{postdocs} postdoc · {phd} Ph.D. students · {ms} M.S. student',
        'LEADERSHIP': '\n'.join(profile_card(p, True) for p in data['current'] if p['group']=='leadership'),
        'GRADUATE': '\n'.join(profile_card(p) for p in data['current'] if p['group']=='graduate'),
        'MASTERS': '\n'.join(alumni_row(p) for p in data['masters']),
        'POSTDOCS': '\n'.join(profile_card(p) for p in data['former_postdocs']),
        'UNDERGRADUATES': '\n'.join(profile_card(p) for p in data['undergraduate_alumni']),
        'UPDATED': esc(data['updated']),
    }
    output = (ROOT/'templates/people.template.html').read_text(encoding='utf-8')
    for key, value in replacements.items():
        token = '{{' + key + '}}'
        if token not in output:
            raise ValueError(f'Missing template placeholder: {token}')
        output = output.replace(token, value)
    if re.search(r'\{\{[A-Z_]+\}\}', output):
        raise ValueError('Unresolved template placeholder.')
    (ROOT/'people.html').write_text(output, encoding='utf-8')
    print(f'Built people.html: {len(data["current"])} current profiles; {len(data["masters"])} degree records; '
          f'{len(data["former_postdocs"])} former postdocs; {len(data["undergraduate_alumni"])} undergraduate alumni.')

if __name__ == '__main__':
    try:
        build()
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f'Could not build People page: {exc}', file=sys.stderr)
        sys.exit(1)
