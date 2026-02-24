# Resume — Shreyas Ragavan

Org-mode based resume with automated PDF/HTML export via [RenderCV](https://rendercv.com) (Typst backend) and GitHub Actions CI/CD.

## How it works

```
resume.org  ──(C-c r r)──►  src/Shreyas_Ragavan_CV.yaml  ──(rendercv render)──►  PDF / HTML / Markdown
```

- **`resume.org`** is the editing surface — all content lives here in plain org-mode.
- **`org-to-rendercv.el`** (loaded automatically via `.dir-locals.el`) reads the org buffer and regenerates the YAML, then invokes `rendercv render` in a compilation buffer.
- **`src/orgrendercv/`** is a custom RenderCV theme (based on `classic`) that controls the visual layout via Jinja2 + Typst templates.

## Project structure

```
├── resume.org                          # Source of truth — edit here
├── org-to-rendercv.el                  # Emacs Lisp exporter (org → YAML → render)
├── .dir-locals.el                      # Loads exporter, binds C-c r r in org buffers
├── requirements.txt                    # rendercv[full]==2.6
├── src/
│   ├── Shreyas_Ragavan_CV.yaml         # RenderCV input (auto-generated, do not edit)
│   ├── shrysr/                         # Custom theme
│   │   ├── __init__.py                 # Pydantic schema for theme design settings
│   │   ├── Preamble.j2.typ             # Typst document setup
│   │   ├── Header.j2.typ               # Name / contact header
│   │   ├── SectionBeginning.j2.typ     # Section title (uppercase)
│   │   ├── SectionEnding.j2.typ
│   │   └── entries/                    # Entry-type templates
│   │       ├── ExperienceEntry.j2.typ
│   │       ├── EducationEntry.j2.typ
│   │       └── ...
│   └── html/
│       └── Full.html                   # Custom HTML template
├── .github/workflows/
│   └── build-resume.yml                # CI: pip install rendercv → render → release
└── copy-to-icloud.sh                   # Local convenience: copy PDF to iCloud Drive
```

## Local workflow

### Prerequisites

- Emacs 29+ with org-mode
- Python 3.12+ (or use the venv already at `venv/`)

```bash
# One-time: install rendercv into the local venv
python -m venv venv
pip install -r requirements.txt
```

### Export

Open `resume.org` in Emacs, then:

```
C-c r r   →  regenerates src/Shreyas_Ragavan_CV.yaml and runs rendercv render
```

Or render manually from the command line:

```bash
cd src
../venv/bin/rendercv render Shreyas_Ragavan_CV.yaml
# Output: src/rendercv_output/
```

### Editing content

Content lives in `resume.org` using standard org-mode structure:

```org
#+LATEX_HEADER: \newcommand{\resumename}{Shreyas Ragavan}
#+LATEX_HEADER: \newcommand{\resumeemail}{...}

* EXPERIENCE
** Machine Learning Operations Engineer
   :PROPERTIES:
   :COMPANY:  Definity Financial
   :PERIOD:   Jun 2022 - Present
   :LOCATION: Vancouver, Canada
   :END:
   - Bullet point one
   - Bullet point two
```

The exporter reads `:COMPANY:`, `:PERIOD:`, `:LOCATION:` properties and bullet lists,
converts org bold (`*text*`) to markdown bold (`**text**`), and parses period strings
into ISO dates (`Jun 2022` → `2022-06`).

## YAML design settings

Visual layout is controlled by the `design:` block in `src/Shreyas_Ragavan_CV.yaml`.
Key settings and what they do:

| Setting | Effect |
|---|---|
| `design.theme: orgrendercv` | Selects the custom theme in `src/orgrendercv/` |
| `design.entries.short_second_row: false` | Bullets span full page width; date in right column of title row only |
| `design.entries.date_and_location_width` | Width of the right date column |
| `design.sections.show_time_spans_in: []` | Disables automatic duration calculation |
| `design.templates.experience_entry.main_column` | Column template string for experience entries |

## CI/CD

Push to `main` triggers `.github/workflows/build-resume.yml`:

1. Install `rendercv[full]==2.6` from `requirements.txt`
2. `rendercv render src/Shreyas_Ragavan_CV.yaml`
3. Upload `dist/Shreyas_Ragavan-Resume.pdf` as a 90-day artifact
4. Create a GitHub Release with the PDF attached

## Color palette

| Role | Color | Used for |
|---|---|---|
| Primary blue | `rgb(37, 99, 149)` | Name, section titles |
| Secondary gray | `rgb(89, 89, 89)` | Body text |
| Accent slate | `rgb(52, 73, 94)` | Headline, connections |
| Light gray | `rgb(127, 140, 141)` | Footer |
| Teal | `rgb(22, 160, 133)` | Links |
