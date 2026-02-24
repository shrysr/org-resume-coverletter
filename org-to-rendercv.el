;;; org-to-rendercv.el --- Export resume.org to RenderCV YAML -*- lexical-binding: t; -*-

;; Usage: M-x resume/org-to-rendercv
;; Reads the current buffer (resume.org), writes src/Shreyas_Ragavan_CV.yaml,
;; then runs `rendercv render` in a compilation buffer.
;;
;; Bind via .dir-locals.el:
;;   ((org-mode . ((eval . (local-set-key (kbd "C-c r r") #'resume/org-to-rendercv)))))

;;; Personal info extraction

(defun resume/get-latex-command-value (command-name)
  "Extract value from a LaTeX \\newcommand definition in current buffer."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward
           (format "\\\\newcommand{\\\\%s}{\\([^}]*\\)}" command-name) nil t)
      (string-trim (match-string 1)))))

(defun resume/get-def-value (command-name)
  "Extract value from a LaTeX \\def definition in current buffer."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward
           (format "\\\\def\\\\%s{\\([^}]*\\)}" command-name) nil t)
      (string-trim (match-string 1)))))

(defun resume/extract-personal-info ()
  "Return an alist of personal info from LaTeX \\newcommand headers."
  (list
   (cons 'name     (resume/get-latex-command-value "resumename"))
   (cons 'email    (resume/get-latex-command-value "resumeemail"))
   (cons 'phone    (resume/get-latex-command-value "resumephone"))
   (cons 'website  (resume/get-latex-command-value "resumewebsite"))
   (cons 'linkedin (resume/get-latex-command-value "resumelinkedin"))
   (cons 'github   (resume/get-latex-command-value "resumegithub"))))

;;; LinkedIn/GitHub username extraction

(defun resume/linkedin-username (url)
  "Extract LinkedIn username from a profile URL."
  (when (and url (string-match "linkedin\\.com/in/\\([^/]+\\)" url))
    (match-string 1 url)))

(defun resume/github-username (url)
  "Extract GitHub username from a profile URL."
  (when (and url (string-match "github\\.com/\\([^/]+\\)$" url))
    (match-string 1 url)))

;;; Org-mode tree parsing

(defun resume/get-top-level-heading (title)
  "Return the org element for the top-level heading with TITLE (case-insensitive)."
  (org-element-map (org-element-parse-buffer) 'headline
    (lambda (hl)
      (when (and (= 1 (org-element-property :level hl))
                 (string-equal-ignore-case
                  (org-element-interpret-data (org-element-property :title hl))
                  title))
        hl))
    nil t))

(defun resume/get-children (heading)
  "Return a list of direct child headlines of HEADING element."
  (org-element-map (org-element-contents heading) 'headline
    (lambda (hl)
      (when (= 2 (org-element-property :level hl))
        hl))
    nil))

(defun resume/headline-text (hl)
  "Return plain text of headline HL title."
  (string-trim
   (substring-no-properties
    (org-element-interpret-data (org-element-property :title hl)))))

(defun resume/headline-bullets (hl)
  "Return list of plain-text bullet strings under headline HL."
  (let (bullets)
    (org-element-map (org-element-contents hl) 'item
      (lambda (item)
        (let ((text (org-element-map (org-element-contents item) 'paragraph
                      (lambda (p)
                        (string-trim
                         (substring-no-properties
                          (org-element-interpret-data p))))
                      nil t)))
          (when text (push text bullets)))))
    (nreverse bullets)))

;;; Org-mode → markdown conversion for highlights

(defun resume/org-to-md (text)
  "Convert org-mode inline markup to markdown in TEXT.
Handles *bold* → **bold** conversion."
  ;; Org bold: *text* → markdown bold: **text**
  (replace-regexp-in-string
   "\\*\\([^*\n]+\\)\\*"
   "**\\1**"
   text))

;;; YAML helpers

(defun resume/yaml-string (s)
  "Return S as a double-quoted YAML string with internal quotes escaped."
  (format "\"%s\"" (replace-regexp-in-string "\"" "\\\\\"" (or s ""))))

(defun resume/yaml-indent (level text)
  "Indent TEXT by LEVEL * 2 spaces."
  (let ((prefix (make-string (* level 2) ?\s)))
    (mapconcat (lambda (line) (concat prefix line))
               (split-string text "\n")
               "\n")))

;;; Section formatters

(defun resume/format-summary (heading)
  "Format the SUMMARY section from org HEADING."
  (let* ((children (resume/get-children heading))
         ;; Try children bullets first, else paragraph text
         (text
          (or
           ;; Check for direct paragraph text in the section body
           (let ((para (org-element-map (org-element-contents heading) 'paragraph
                         (lambda (p)
                           (string-trim
                            (substring-no-properties
                             (org-element-interpret-data p))))
                         nil t)))
             (when (and para (not (string-empty-p para))) para))
           ;; Fall back to first child heading text
           (when children
             (resume/headline-text (car children))))))
    (when text
      (format "    summary:\n      - %s\n"
              (resume/yaml-string (resume/org-to-md text))))))

(defun resume/format-skills (heading)
  "Format the SKILLS section from org HEADING."
  (let ((items
         (org-element-map (org-element-contents heading) 'item
           (lambda (item)
             (let ((raw (string-trim
                         (substring-no-properties
                          (org-element-interpret-data
                           (car (org-element-contents item)))))))
               ;; Parse "Label: details" format from org list items
               ;; e.g., "*Machine Learning & AI:* Python, R..."
               (when (string-match
                      "\\*?\\([^*:]+\\)\\*?:\\*?\\s-*\\(.*\\)" raw)
                 (list (string-trim (match-string 1 raw))
                       (string-trim (match-string 2 raw)))))))))
    (when items
      (concat "    skills:\n"
              (mapconcat
               (lambda (item)
                 (when item
                   (format "      - label: %s\n        details: %s\n"
                           (resume/yaml-string (car item))
                           (resume/yaml-string (cadr item)))))
               items
               "")))))

(defun resume/format-experience-entry (hl)
  "Format one ExperienceEntry YAML block from org headline HL."
  (let* ((position (resume/headline-text hl))
         (company  (org-element-property :COMPANY hl))
         (period   (org-element-property :PERIOD hl))
         (location (org-element-property :LOCATION hl))
         (bullets  (resume/headline-bullets hl))
         ;; Parse "Mon YYYY - Mon YYYY" or "Mon YYYY - Present"
         (dates    (resume/parse-period period)))
    (concat
     (format "      - company: %s\n" (resume/yaml-string company))
     (format "        position: %s\n" (resume/yaml-string position))
     (when location
       (format "        location: %s\n" (resume/yaml-string location)))
     (format "        start_date: %s\n" (car dates))
     (format "        end_date: %s\n" (cdr dates))
     (when bullets
       (concat "        highlights:\n"
               (mapconcat
                (lambda (b)
                  (format "          - %s\n"
                          (resume/yaml-string (resume/org-to-md b))))
                bullets ""))))))

(defun resume/format-education-entry (hl)
  "Format one EducationEntry YAML block from org headline HL."
  (let* ((raw-title (resume/headline-text hl))
         ;; Split "DEGREE. Area" → degree + area
         (degree-area (resume/parse-degree-title raw-title))
         (degree      (car degree-area))
         (area        (cdr degree-area))
         (institution (org-element-property :INSTITUTION hl))
         (period      (org-element-property :PERIOD hl))
         (location    (org-element-property :LOCATION hl))
         (dates       (resume/parse-period period)))
    (concat
     (format "      - institution: %s\n" (resume/yaml-string institution))
     (format "        area: %s\n" (resume/yaml-string area))
     (format "        degree: %s\n" (resume/yaml-string degree))
     (when location
       (format "        location: %s\n" (resume/yaml-string location)))
     (format "        start_date: %s\n" (car dates))
     (format "        end_date: %s\n" (cdr dates)))))

;;; Date parsing helpers

(defun resume/month-number (abbr)
  "Return zero-padded month number string for month abbreviation ABBR."
  (let ((months '(("jan" . "01") ("feb" . "02") ("mar" . "03")
                  ("apr" . "04") ("may" . "05") ("jun" . "06")
                  ("jul" . "07") ("aug" . "08") ("sep" . "09")
                  ("oct" . "10") ("nov" . "11") ("dec" . "12"))))
    (cdr (assoc (downcase (substring abbr 0 3)) months))))

(defun resume/parse-single-date (date-str)
  "Parse DATE-STR like 'Jun 2022' or 'Present' into YYYY-MM or 'present'."
  (let ((trimmed (string-trim date-str)))
    (if (string-equal-ignore-case trimmed "present")
        "present"
      (when (string-match "\\([A-Za-z]+\\)\\s-+\\([0-9]\\{4\\}\\)" trimmed)
        (format "%s-%s"
                (match-string 2 trimmed)
                (resume/month-number (match-string 1 trimmed)))))))

(defun resume/parse-period (period)
  "Parse PERIOD string 'Mon YYYY - Mon YYYY' into (start . end) cons."
  (when period
    (if (string-match "\\(.+\\)\\s-+-+\\s-*\\(.+\\)" period)
        ;; Capture both match strings before any nested string-match call
        ;; overwrites the global match data.
        (let ((s1 (match-string 1 period))
              (s2 (match-string 2 period)))
          (cons (resume/parse-single-date s1)
                (resume/parse-single-date s2)))
      (cons period "present"))))

(defun resume/parse-degree-title (title)
  "Parse 'DEGREE. Area Title' into (degree . area) cons.
Examples:
  'MS. Advanced Mechanical Engineering' → ('MS' . 'Advanced Mechanical Engineering')
  'B.Tech. Automotive Design' → ('B.Tech' . 'Automotive Design')"
  (cond
   ;; Match patterns like "MS. " or "B.Tech. "
   ((string-match "^\\([A-Za-z.]+\\)\\.\\s-+\\(.*\\)$" title)
    (cons (string-trim (match-string 1 title))
          (string-trim (match-string 2 title))))
   ;; Fallback: whole title as area, empty degree
   (t (cons "" title))))

;;; Main YAML generation

(defun resume/generate-yaml (info)
  "Generate the full RenderCV YAML string from INFO alist."
  (let* ((name     (alist-get 'name info))
         (email    (alist-get 'email info))
         (phone    (alist-get 'phone info))
         (website  (alist-get 'website info))
         (linkedin (resume/linkedin-username (alist-get 'linkedin info)))
         (github   (resume/github-username (alist-get 'github info)))
         (tree     (org-element-parse-buffer))
         (summary-hl   (resume/get-top-level-heading "SUMMARY"))
         (skills-hl    (resume/get-top-level-heading "SKILLS"))
         (exp-hl       (resume/get-top-level-heading "EXPERIENCE"))
         (edu-hl       (resume/get-top-level-heading "EDUCATION"))
         (exp-entries  (when exp-hl (resume/get-children exp-hl)))
         (edu-entries  (when edu-hl (resume/get-children edu-hl))))
    (concat
     "# yaml-language-server: $schema=https://raw.githubusercontent.com/rendercv/rendercv/refs/tags/v2.6/schema.json\n"
     "cv:\n"
     (format "  name: %s\n" (resume/yaml-string name))
     (format "  email: %s\n" (resume/yaml-string email))
     (format "  phone: %s\n" (resume/yaml-string phone))
     (format "  website: %s\n" website)
     "  social_networks:\n"
     (format "    - network: LinkedIn\n      username: %s\n" linkedin)
     (format "    - network: GitHub\n      username: %s\n" github)
     "\n  sections:\n"
     ;; Summary
     (when summary-hl (resume/format-summary summary-hl))
     "\n"
     ;; Skills
     (when skills-hl (resume/format-skills skills-hl))
     "\n"
     ;; Experience
     (when exp-entries
       (concat "    experience:\n"
               (mapconcat #'resume/format-experience-entry exp-entries "")))
     "\n"
     ;; Education
     (when edu-entries
       (concat "    education:\n"
               (mapconcat #'resume/format-education-entry edu-entries "")))
     "\n"
     ;; Design section (static — matches src/Shreyas_Ragavan_CV.yaml)
     (resume/design-block))))

(defun resume/design-block ()
  "Return the static design: YAML block."
  "design:
  theme: shrysr
  page:
    size: a4
    top_margin: 0.5in
    bottom_margin: 0.5in
    left_margin: 0.5in
    right_margin: 0.5in
    show_footer: true
    show_top_note: false
  colors:
    body: \"rgb(89, 89, 89)\"
    name: \"rgb(37, 99, 149)\"
    headline: \"rgb(52, 73, 94)\"
    connections: \"rgb(52, 73, 94)\"
    section_titles: \"rgb(37, 99, 149)\"
    links: \"rgb(22, 160, 133)\"
    footer: \"rgb(127, 140, 141)\"
  typography:
    font_family:
      body: Source Sans 3
      name: Source Sans 3
      headline: Source Sans 3
      connections: Source Sans 3
      section_titles: Source Sans 3
    font_size:
      body: 10pt
    alignment: justified
  header:
    alignment: center
    space_below_name: 0.3cm
    space_below_headline: 0.3cm
    space_below_connections: 0.4cm
    connections:
      show_icons: true
      separator: \" | \"
      phone_number_format: international
  section_titles:
    type: with_partial_line
    space_above: 0.5cm
    space_below: 0.25cm
  sections:
    space_between_regular_entries: 0.8em
    show_time_spans_in: []
  entries:
    date_and_location_width: 3.5cm
    short_second_row: false
    highlights:
      bullet: \"•\"
      space_above: 0.12cm
      space_between_items: 0.05cm
  templates:
    footer: \"PAGE_NUMBER/TOTAL_PAGES\"
    experience_entry:
      main_column: \"**POSITION** | COMPANY\\nHIGHLIGHTS\"
      date_and_location_column: \"DATE\"
    education_entry:
      main_column: \"**DEGREE** AREA, INSTITUTION | LOCATION\\nHIGHLIGHTS\"
      degree_column: null
      date_and_location_column: \"DATE\"
")

;;; Top-level command

;;;###autoload
(defun resume/org-to-rendercv ()
  "Export current resume.org buffer to src/Shreyas_Ragavan_CV.yaml and render.
Writes the YAML file relative to the file being visited, then runs
`rendercv render` in a *rendercv* compilation buffer."
  (interactive)
  (unless (eq major-mode 'org-mode)
    (user-error "This command must be run from an org-mode buffer"))
  (let* ((org-file (buffer-file-name))
         (project-root (file-name-directory org-file))
         (yaml-path (expand-file-name "src/Shreyas_Ragavan_CV.yaml" project-root))
         (venv-rendercv (expand-file-name "venv/bin/rendercv" project-root))
         (rendercv-cmd (if (file-executable-p venv-rendercv)
                           venv-rendercv
                         "rendercv"))
         ;; Parse the org buffer in its own temp context
         (info (with-current-buffer (current-buffer)
                 (resume/extract-personal-info)))
         (yaml (with-current-buffer (current-buffer)
                 (org-element-cache-reset)
                 (resume/generate-yaml info))))
    ;; Write YAML
    (make-directory (file-name-directory yaml-path) t)
    (with-temp-file yaml-path
      (insert yaml))
    (message "Wrote %s" yaml-path)
    ;; Render in compilation buffer
    (let ((default-directory (expand-file-name "src/" project-root))
          (compile-command (format "%s render Shreyas_Ragavan_CV.yaml" rendercv-cmd)))
      (compile compile-command))))

(provide 'org-to-rendercv)
;;; org-to-rendercv.el ends here
