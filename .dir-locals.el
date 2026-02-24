;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((org-mode
  . ((eval . (progn
               (load-file (expand-file-name "org-to-rendercv.el"
                                            (file-name-directory
                                             (or load-file-name buffer-file-name))))
               (local-set-key (kbd "C-c r r") #'resume/org-to-rendercv))))))
