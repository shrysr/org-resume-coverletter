# Org-Mode Resume System

An automated resume and cover letter system using Emacs Org mode with LaTeX export and GitHub Actions CI/CD.

## 📁 Project Structure

```
├── resume.org              # Main resume in Org mode format
├── cover-letter.org        # Cover letter template with placeholders
├── .dir-locals.el          # Directory-local export configuration
├── .github/workflows/      # GitHub Actions for automated builds
├── test-export.sh          # Local testing script for exports
└── dist/                   # Generated output files (auto-created)
```

## 🚀 Features

- **Modern Design**: Clean, professional layout optimized for both screen and print
- **Property-Based System**: Uses org properties (COMPANY, PERIOD, LOCATION) for structured data
- **Configurable Colors**: Elegant color scheme emphasizing critical information
- **Multiple Formats**: Automatic export to PDF and HTML
- **Standard Export**: Works with standard org export commands (C-c C-e l p)
- **Easy Customization**: Separate LATEX_HEADER lines for quick contact info editing
- **Template System**: Cover letter with customizable placeholders
- **Automated Builds**: GitHub Actions workflow triggers on push to main
- **GitHub Pages**: Automatic deployment of HTML versions

## 🎨 Color Scheme

The system uses a professional color palette defined in the LATEX_HEADERs:
- **Primary**: Professional blue (#1F4E79) for headers and links
- **Accent**: Dark gray (#333333) for job titles and emphasis
- **Supporting**: Light gray (#808080) for dates and locations
- **Main Text**: Pure black for optimal readability

## 📝 Usage

### Local Development

1. **Edit resume content**: Modify `resume.org` with your information
   - Update contact info by editing individual LATEX_HEADER lines (lines 35-41)
   - Add experience entries using org properties: COMPANY, PERIOD, LOCATION
   - Experience formatting is handled automatically: "Position | Company —— Period"

2. **Customize cover letter**: Update placeholders in `cover-letter.org`:
   - `[COMPANY NAME]` - Target company name
   - `[POSITION TITLE]` - Position title
   - `[HIRING MANAGER NAME]` - Hiring manager's name
   - `[SPECIFIC SKILLS/REQUIREMENTS FROM JOB POSTING]` - Skills from job posting

3. **Export locally**:
   - **Standard org export**: `C-c C-e l p` (PDF) or `C-c C-e l h` (HTML)
   - **Test script**: Run `./test-export.sh` to validate and export both files
   - **Batch export**: 
     ```bash
     emacs --batch resume.org --eval "(setq org-confirm-babel-evaluate nil)" --eval "(require 'ox-latex)" --eval "(org-latex-export-to-pdf)"
     ```

### Automated Builds

Push changes to `main` branch to trigger automatic:
- PDF and HTML generation
- GitHub Pages deployment
- Release creation with downloadable PDFs

## 📋 Customization

### Contact Information

Edit these LATEX_HEADER lines in `resume.org` for easy customization:
```org
#+LATEX_HEADER: \newcommand{\resumename}{Shreyas Ragavan}
#+LATEX_HEADER: \newcommand{\resumeemail}{shreyas@fastmail.com}
#+LATEX_HEADER: \newcommand{\resumephone}{+1 279-258-9720}
#+LATEX_HEADER: \newcommand{\resumelinkedin}{https://linkedin.com/in/shreyasragavan}
#+LATEX_HEADER: \newcommand{\resumewebsite}{https://shreyas.ragavan.co}
#+LATEX_HEADER: \newcommand{\resumegithub}{https://github.com/shrysr}
```

### Experience Entries

Use org properties for structured data:
```org
** Position Title
   :PROPERTIES:
   :COMPANY: Company Name
   :PERIOD: June 2022 - Present
   :LOCATION: City, Country
   :END:
```

The babel export filter automatically formats these as: "Position Title | Company Name —— June 2022 - Present"

### Cover Letter Variables

Update placeholders in `cover-letter.org`:
- `[COMPANY NAME]` - Target company name
- `[POSITION TITLE]` - Position title  
- `[HIRING MANAGER NAME]` - Addressee name
- `[SPECIFIC SKILLS/REQUIREMENTS FROM JOB POSTING]` - Skills from job posting

### Colors and Styling

Modify color definitions in the LATEX_HEADER sections:
```org
#+LATEX_HEADER: \definecolor{primary}{RGB}{31, 78, 121}
#+LATEX_HEADER: \definecolor{secondary}{RGB}{102, 102, 102}
#+LATEX_HEADER: \definecolor{accent}{RGB}{51, 51, 51}
#+LATEX_HEADER: \definecolor{light}{RGB}{128, 128, 128}
```

## 🔧 Requirements

### Local Setup
- Emacs 29+ with org-mode
- TeXLive (full installation recommended)
- LaTeX packages: fontawesome5, xcolor, titlesec, hyperref, geometry, array, tabularx, calc
- For babel evaluation: `(setq org-confirm-babel-evaluate nil)` in your Emacs config

### GitHub Actions
- Runs on Ubuntu latest
- Auto-installs Emacs, TeXLive, and dependencies
- Requires GitHub Pages to be enabled in repository settings

## 📊 Output Files

Generated files in `dist/` directory:
- `ShreyasRagavan-Resume.pdf` - PDF resume
- `ShreyasRagavan-Resume.html` - HTML resume
- `ShreyasRagavan-CoverLetter.pdf` - PDF cover letter
- `ShreyasRagavan-CoverLetter.html` - HTML cover letter

## 🌐 Access Points

- **GitHub Pages**: `https://[username].github.io/org-resume/`
- **Latest Release**: Check repository releases for downloadable PDFs
- **Actions Artifacts**: Download from GitHub Actions runs

## 🛠️ Troubleshooting

### LaTeX Export Issues

#### "There's no line here to end" error
- Fixed in current version by using conditional subtitle logic
- Ensure empty subtitle properties are handled correctly

#### Property verbatim blocks appearing in output
- Requires the babel export filter in `resume.org`
- The filter cleans up property drawers and formats headlines
- Do not remove the `#+BEGIN_SRC emacs-lisp` block - it's essential for property extraction

#### Standard org export hanging or failing
- Add `(setq org-confirm-babel-evaluate nil)` to your Emacs config
- Or use batch export with `--eval "(setq org-confirm-babel-evaluate nil)"`

### Cover Letter Errors

#### "Unknown LaTeX class 'letter'"
- Fixed by using `#+LATEX_CLASS: article` instead of `letter`
- Current version uses article class with custom formatting

### GitHub Actions Failures
- Check workflow logs in Actions tab
- Ensure GitHub Pages is enabled in repository settings
- Verify `GITHUB_TOKEN` has necessary permissions

### Missing Dependencies
- Install all required LaTeX packages: `tlmgr install fontawesome5 xcolor titlesec`
- Ensure TeXLive installation includes geometry, array, tabularx, calc packages