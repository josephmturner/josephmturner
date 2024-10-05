(add-to-list 'load-path "liaison")

(require 'ox)
(require 'ox-publish)
(require 'liaison)

(defun my/string-from-file (path)
  "Return file content as string."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

;; Add time zone to timestamp
(setq org-html-metadata-timestamp-format "%Y-%m-%d %a %H:%M %Z")

;;; Redefinition of built-in org-html-format-spec:
(defun org-html-format-spec (info)
  "Return format specification for preamble and postamble.
INFO is a plist used as a communication channel."
  (let ((timestamp-format (plist-get info :html-metadata-timestamp-format)))
    `((?t . ,(org-export-data (plist-get info :title) info))
      (?s . ,(org-export-data (plist-get info :subtitle) info))
      (?d . ,(org-export-data (org-export-get-date info timestamp-format)
			      info))
      (?T . ,(format-time-string timestamp-format))
      (?a . ,(org-export-data (plist-get info :author) info))
      (?e . ,(mapconcat
	      (lambda (e) (format "<a href=\"mailto:%s\">%s</a>" e e))
	      (split-string (plist-get info :email)  ",+ *")
	      ", "))
      (?c . ,(plist-get info :creator))
      (?C . ,(let ((file (plist-get info :input-file)))
	       (format-time-string timestamp-format
				   (and file (file-attribute-modification-time
					      (file-attributes file))))))
      (?l . ,(liaison-get-resource-url 'log)))))

(defun my/publish-sitemap (title list)
  "Like `org-publish-sitemap-default', but pulls in the setup file."
  (concat "#+TITLE: " title "\n"
          "#+SETUPFILE: ./setup.org" "\n\n"
	  (org-list-to-org list)))

;; Define the publishing project
(setq org-publish-project-alist
      (list
       (list "breathe-content"
             :recursive t
             :base-directory "./content"
             :exclude "setup.org"
             :publishing-directory "./public"
             :publishing-function 'org-html-publish-to-html
             :auto-sitemap t
             :sitemap-title "Sitemap for breatheoutbreathe.in"
             :sitemap-function #'my/publish-sitemap
             :with-author nil        ;; Don't add author name
             :with-toc nil           ;; Don't add table of contents
             :section-numbers nil    ;; Don't add section numbers
             :with-sub-superscript nil  ;; Don't interpret _ as underscore
             :html-preamble (my/string-from-file "./templates/preamble.html")
	     :html-postamble (my/string-from-file "./templates/postamble.html"))
       (list "breathe-content-raw"
             :recursive t
             :base-directory "./content"
             :publishing-directory "./public"
             :publishing-function 'org-publish-attachment)
       (list "breathe-css"
             :recursive t
             :base-directory "./css/"
             :base-extension "css"
             :publishing-directory "./public/css"
             :publishing-function 'org-publish-attachment)
       (list "breathe-img"
             :recursive t
             :base-directory "./img/"
             :base-extension "png\\|svg"
             :publishing-directory "./public/img"
             :publishing-function 'org-publish-attachment)
       (list "breathe" :components '("breathe-content" "breathe-content-raw" "breathe-css" "breathe-img"))))

(setq org-html-validation-link nil)            ;; Don't show validation link
(setq org-html-head-include-scripts nil)       ;; Use our own scripts
(setq org-html-head-include-default-style nil) ;; Use our own styles

;; Prevent creation of backup files
(setq make-backup-files nil)

;; Generate the site output
;; When adding new files, add t.
;; (org-publish-all t)
(org-publish-all)

(message "Build complete!")
