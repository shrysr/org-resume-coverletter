;;; Directory Local Variables for org-resume
;;; For more information see (info "(emacs) Directory Variables")

((nil . ((eval . (progn
                   (require 'ox-latex)
                   (defun my-resume-headline-formatter (headline contents info)
                     (let* ((level (org-element-property :level headline))
                            (title (org-element-property :title headline))
                            (title-text (org-export-data title info))
                            (company (org-element-property :COMPANY headline))
                            (period (org-element-property :PERIOD headline))
                            (location (org-element-property :LOCATION headline))
                            (institution (org-element-property :INSTITUTION headline)))
                       (cond
                        ((= level 1)
                         (format "\\section{%s}\n" title-text))
                        ;; Level 2 headlines - format as: Title | Company/Institution ---- Period (right-aligned)
                        ((= level 2)
                         (let ((org-name (cond
                                          ;; Use company if it exists and is not empty
                                          ((and company (not (string= company ""))) company)
                                          ;; Use institution if it exists and is not empty  
                                          ((and institution (not (string= institution ""))) institution)
                                          ;; Otherwise no organization
                                          (t nil)))
                               (period-text (or period "")))
                           (if org-name
                               (format "\\subsection{%s \\textbar\\ %s \\hfill \\textcolor{light}{\\textbf{%s}}}\n"
                                       title-text org-name period-text)
                             (format "\\subsection{%s \\hfill \\textcolor{light}{\\textbf{%s}}}\n"
                                     title-text period-text))))
                        (t
                         (org-latex-headline headline contents info)))))))))
 (org-mode . ((org-export-allow-bind-keywords . t)
              (org-latex-format-headline-function . my-resume-headline-formatter))))