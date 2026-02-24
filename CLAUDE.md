# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Pipeline overview

```
resume.org  ──(C-c r r)──►  src/Shreyas_Ragavan_CV.yaml  ──(rendercv)──►  PDF / HTML
```

- **`resume.org`** is the source of truth for all content. Edit here.
- **`org-to-rendercv.el`** is the Emacs Lisp exporter. It parses `resume.org` and writes
  the YAML, then calls `rendercv render` in a compilation buffer.
- **`src/Shreyas_Ragavan_CV.yaml`** is auto-generated. Do not edit it directly.
- **`src/orgrendercv/`** is the custom RenderCV theme (Pydantic schema + Jinja2/Typst templates).

## Development commands

```bash
# Render from the command line (from project root)
cd src && ../venv/bin/rendercv render Shreyas_Ragavan_CV.yaml

# Live reload during design iteration
cd src && ../venv/bin/rendercv render --watch Shreyas_Ragavan_CV.yaml

# Install/update dependencies
venv/bin/pip install -r requirements.txt
```

From Emacs (in resume.org):
```
C-c r r   →  runs resume/org-to-rendercv (parse org → write YAML → render)
```

## Key files

| File | Role |
|---|---|
| `resume.org` | Content source — org properties + bullet lists |
| `org-to-rendercv.el` | Exporter: org → YAML → rendercv render |
| `.dir-locals.el` | Auto-loads exporter, binds C-c r r |
| `src/Shreyas_Ragavan_CV.yaml` | Generated RenderCV input (do not edit) |
| `src/orgrendercv/__init__.py` | Pydantic model for all theme design parameters |
| `src/orgrendercv/SectionBeginning.j2.typ` | Section titles (uses `#upper[...]`) |
| `src/orgrendercv/entries/ExperienceEntry.j2.typ` | Experience entry layout |
| `src/orgrendercv/entries/EducationEntry.j2.typ` | Education entry layout |
| `requirements.txt` | `rendercv[full]==2.6` |

## Org source structure

Personal info is stored as `#+CV_*` org keywords at the top of `resume.org`:

```org
#+CV_NAME: Shreyas Ragavan
#+CV_EMAIL: shreyas@fastmail.com
#+CV_PHONE: +1 647-671-1851
#+CV_WEBSITE: https://shreyas.ragavan.co
#+CV_LINKEDIN: shreyasragavan    ← username only, not full URL
#+CV_GITHUB: shrysr              ← username only, not full URL
```

These are read by `resume/extract-personal-info` via `org-collect-keywords`.

Experience and education entries use org properties:

```org
** Job Title
   :PROPERTIES:
   :COMPANY:  Company Name
   :PERIOD:   Jun 2022 - Present
   :LOCATION: Vancouver, Canada
   :END:
   - Bullet highlight one
   - Bullet highlight two
```

```org
** MS. Advanced Mechanical Engineering
   :PROPERTIES:
   :INSTITUTION: University of Leeds
   :PERIOD:      Sep 2010 - Nov 2011
   :LOCATION:    United Kingdom
   :END:
```

## RenderCV notes

- Always render from the `src/` directory (theme path resolution requires this).
- `page.size: a4` (not `a4paper`).
- `show_time_spans_in: []` disables duration calculation in the experience section.
- `degree_column: null` hides the degree column in education entries.
- `entries.short_second_row: false` makes bullet highlights span the full page width,
  with the date column only in the title row.
- `#upper[...]` is the correct Typst 0.14.8 syntax for uppercase; `text(transform:
  "uppercase")` is not supported.

## Exporter notes (org-to-rendercv.el)

- `resume/parse-period` captures both regex match groups into `let` locals *before*
  calling `resume/parse-single-date`, to avoid match-data clobbering by nested
  `string-match` calls.
- Skills items are parsed with `"\\*?\\([^*:]+\\)\\*?:\\*?\\s-*\\(.*\\)"` to strip
  the closing org bold marker `*` that follows the label colon.
- Org bold (`*text*`) is converted to markdown bold (`**text**`) via `resume/org-to-md`.

## CI/CD

`.github/workflows/build-resume.yml` runs on push to `main`:
1. Python 3.12 + `rendercv[full]==2.6`
2. `rendercv render src/Shreyas_Ragavan_CV.yaml`
3. Upload PDF artifact (90-day retention)
4. Create GitHub Release with PDF

## Important: do not edit the YAML directly

Always edit `resume.org` and regenerate via `C-c r r`. The YAML is the build artifact,
not the source.
