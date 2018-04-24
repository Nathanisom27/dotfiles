;;; theworld.el --- make the thing
;;; commentary:
;;; code:

(defun init-use-package()
  (require 'package)
  (setq package-enable-at-startup nil)
  (add-to-list 'package-archives
	       '("melpa" . "https://melpa.org/packages/"))

  (package-initialize)

  ;; Bootstrap `use-package'
  (unless (package-installed-p 'use-package)
    (package-refresh-contents)
    (package-install 'use-package))

  (eval-when-compile
    (require 'use-package))
  (setq use-package-always-ensure t)
  )

(defun init-straight()
  (let ((bootstrap-file (concat user-emacs-directory "straight/bootstrap.el"))
	(bootstrap-version 2))
    (unless (file-exists-p bootstrap-file)
      (with-current-buffer
	  (url-retrieve-synchronously
	   "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
	   'silent 'inhibit-cookies)
	(goto-char (point-max))
	(eval-print-last-sexp)))
    (load bootstrap-file nil 'nomessage))

  (straight-use-package 'use-package)
  (setq straight-use-package-by-default t)
  )

(defun neeasade/load(targets)
  (mapc (lambda(target)
	  (funcall (intern (concat "neeasade/" (prin1-to-string target))))
	  )
	targets)
  )

(defun neeasade/helpers()
  (use-package hydra)
  (use-package general)
  (use-package rg)
  (load "~/.emacs.d/lisp/helpers.el")
  )

(defun neeasade/interactive()
  (use-package s)
  (load "~/.emacs.d/lisp/interactive.el")
  )

(defun neeasade/sanity()
  ;; sanity
  (setq
   auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t))
   backup-directory-alist `(("." . "~/.emacs.d/backups"))
   coding-system-for-read 'utf-8
   coding-system-for-write 'utf-8
   delete-old-versions -1
   global-auto-revert-mode t
   inhibit-startup-screen t
   initial-scratch-message ""
   ring-bell-function 'ignore
   sentence-end-double-space nil
   ;; symlinked file
   vc-follow-symlinks t ;; auto follow symlinks
   vc-make-backup-files t
   version-control t
   ;; ouch
   gc-cons-threshold 10000000
   )

  ;; trim gui
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (when (boundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

  ;; other
  (show-paren-mode 1)
  (blink-cursor-mode 0)

  ;; disable semantic mode, this may bite me lets try it out
  (with-eval-after-load 'semantic
    (add-to-list 'semantic-inhibit-functions (lambda () t))
    )

  ;; set default to be handled by global bloat toggle
  (global-font-lock-mode 0)

  (defconst custom-file "~/.emacs.d/custom.el")
  (unless (file-exists-p custom-file)
    (write-region "" nil custom-file))
  (load custom-file)

  ;; allow things to load before we reload settings
  ;; todo: reconsider ^
  ;; (setq desktop-restore-eager 5)
  ;; (setq desktop-path (list "~/.emacs.d"))

  ;; retain session
  (desktop-save-mode 1)

  (setq browse-url-browser-function 'browse-url-generic)

  (if sys/windows?
      (if (executable-find "qutebrowser")
	  (setq browse-url-generic-program "qutebrowser")
	(setq browse-url-browser-function 'browse-url-default-windows-browser)
	)
    )

  (neeasade/bind
   "js" (lambda() (interactive) (neeasade/find-or-open "~/.emacs.d/lisp/scratch.el"))
   "jm" (lambda() (interactive) (counsel-switch-to-buffer-or-window  "*Messages*"))

   "tw" 'whitespace-mode
   "tn" 'linum-mode
   "tl" 'toggle-truncate-lines
   )
  )

(defun neeasade/elisp()
  (load "~/.emacs.d/vendor/le-eval-and-insert-results.el")

  (setq lisp-indent-function 'common-lisp-indent-function)
  (neeasade/bind-leader-mode
   'emacs-lisp
   "er" 'eval-region
   "ei" 'le::eval-and-insert-results
   "eb" 'le::eval-and-insert-all-sexps
   )
  )

(defun neeasade/evil()
  (use-package evil
    ;; for evil-collection
    :init (setq evil-want-integration nil)
    :config (evil-mode 1)
    )

  ;;(use-package evil-collection
  ;;:config (evil-collection-init)
  ;;)

  (defun neeasade/zz-scroll (count)
    ;; window-total-size gets lines count when called with no args
    ;; note: this only works well for buffers that take more than the full screen...
    ;; also doesn't handle when buffer bottom is visible very well.
    (let (
	  (windowcount (/ (window-total-size) 2))
	  (scrollcount (/ (window-total-size) 7))
	  (buffercount (count-lines (point-min) (point-max)))
	  )
      (if (> buffercount windowcount)
	  (evil-scroll-line-down scrollcount)
	nil
	)
      )
    )
  (add-function :after (symbol-function 'evil-scroll-line-to-center) #'neeasade/zz-scroll)

  (general-evil-setup t)

  ;; defaults to fd/spacemacs-like config
  (use-package evil-escape :config (evil-escape-mode))
  (use-package evil-lion :config (evil-lion-mode))
  (use-package evil-surround :config (global-evil-surround-mode 1))
  (use-package evil-commentary :config (evil-commentary-mode))
  (use-package evil-anzu) ;; displays current match and total matches.
  (use-package evil-numbers)


  ;; Overload shifts so that they don't lose the selection
  (define-key evil-visual-state-map (kbd ">") 'djoyner/evil-shift-right-visual)
  (define-key evil-visual-state-map (kbd "<") 'djoyner/evil-shift-left-visual)
  (define-key evil-visual-state-map [tab] 'djoyner/evil-shift-right-visual)
  (define-key evil-visual-state-map [S-tab] 'djoyner/evil-shift-left-visual)

  (defun djoyner/evil-shift-left-visual ()
    (interactive)
    (evil-shift-left (region-beginning) (region-end))
    (evil-normal-state)
    (evil-visual-restore))

  (defun djoyner/evil-shift-right-visual ()
    (interactive)
    (evil-shift-right (region-beginning) (region-end))
    (evil-normal-state)
    (evil-visual-restore))
  )

(defun neeasade/flycheck()
  (use-package flycheck
    :config

    ;; (flycheck) disable jshint since we prefer eslint checking
    (setq-default
     flycheck-disabled-checkers
     (append flycheck-disabled-checkers
	     '(javascript-jshint)))

    ;; use eslint with web-mode for jsx files
    (flycheck-add-mode 'javascript-eslint 'web-mode)
    )

  (neeasade/bind
   ;; Applications
   "e" '(:ignore t :which-key "Errors")
   "en" 'flycheck-next-error
   "ep" 'flycheck-previous-error
   )
  )

(defun neeasade/treemacs()
  (use-package treemacs)
  (use-package treemacs-evil)
  (use-package treemacs-projectile)
  )

(defun neeasade/company()
  (use-package company
    :config
    (load-settings
     "company"
     '(
       idle-delay (if sys/windows? 2 0)
       selection-wrap-around t
       tooltip-align-annotations t
       dabbrev-downcase nil
       dabbrev-ignore-case t
       tooltip-align-annotations t
       tooltip-margin 2
       global-modes '(not
		      org-mode
		      shell-mode
		      circe-chat-mode
		      circe-channel-mode
		      )
       )
     )

    (use-package company-flx
      :config (company-flx-mode +1)
      )

    ;; TODO: investigate tab handling like VS completely
    (define-key company-active-map [tab] 'company-complete)
    )

  (use-package company-quickhelp
    :init
    (company-quickhelp-mode 1)
    (setq company-quickhelp-delay 0.3)
    )
  )

(defun neeasade/editing()
  (use-package editorconfig :config (editorconfig-mode 1))
  (setq tab-width 4)
  (use-package aggressive-indent
	  :config
	(add-hook 'emacs-lisp-mode-hook   #'aggressive-indent-mode)
	(add-hook 'clojure-mode-hook #'aggressive-indent-mode)
    )

  (use-package smartparens
    :config (smartparens-global-mode)
    )

  ;; from https://github.com/syl20bnr/spacemacs/blob/bd7ef98e4c35fd87538dd2a81356cc83f5fd02f3/layers/%2Bdistributions/spacemacs-bootstrap/config.el
  ;; GPLv3
  (defvar spacemacs--indent-variable-alist
    ;; Note that derived modes must come before their sources
    '(((awk-mode c-mode c++-mode java-mode groovy-mode
	idl-mode java-mode objc-mode pike-mode) . c-basic-offset)
      (python-mode . python-indent-offset)
      (cmake-mode . cmake-tab-width)
      (coffee-mode . coffee-tab-width)
      (cperl-mode . cperl-indent-level)
      (css-mode . css-indent-offset)
      (elixir-mode . elixir-smie-indent-basic)
      ((emacs-lisp-mode lisp-mode) . lisp-indent-offset)
      (enh-ruby-mode . enh-ruby-indent-level)
      (erlang-mode . erlang-indent-level)
      (js2-mode . js2-basic-offset)
      (js3-mode . js3-indent-level)
      ((js-mode json-mode) . js-indent-level)
      (latex-mode . (LaTeX-indent-level tex-indent-basic))
      (livescript-mode . livescript-tab-width)
      (mustache-mode . mustache-basic-offset)
      (nxml-mode . nxml-child-indent)
      (perl-mode . perl-indent-level)
      (puppet-mode . puppet-indent-level)
      (ruby-mode . ruby-indent-level)
      (rust-mode . rust-indent-offset)
      (scala-mode . scala-indent:step)
      (sgml-mode . sgml-basic-offset)
      (sh-mode . sh-basic-offset)
      (typescript-mode . typescript-indent-level)
      (web-mode . web-mode-markup-indent-offset)
      (yaml-mode . yaml-indent-offset))
    "An alist where each key is either a symbol corresponding
    to a major mode, a list of such symbols, or the symbol t,
    acting as default. The values are either integers, symbols
    or lists of these.")

  (defun spacemacs//set-evil-shift-width ()
    "Set the value of `evil-shift-width' based on the indentation settings of the
current major mode."
    (let ((shift-width
	   (catch 'break
	     (dolist (test spacemacs--indent-variable-alist)
	       (let ((mode (car test))
		     (val (cdr test)))
		 (when (or (and (symbolp mode) (derived-mode-p mode))
			   (and (listp mode) (apply 'derived-mode-p mode))
			   (eq 't mode))
		   (when (not (listp val))
		     (setq val (list val)))
		   (dolist (v val)
		     (cond
		       ((integerp v) (throw 'break v))
		       ((and (symbolp v) (boundp v))
			(throw 'break (symbol-value v))))))))
	     (throw 'break (default-value 'evil-shift-width)))))
      (when (and (integerp shift-width)
		 (< 0 shift-width))
	(setq-local evil-shift-width shift-width))))

  (add-hook 'after-change-major-mode-hook 'spacemacs//set-evil-shift-width 'append)

  ;; some default indent preferences for different modes
  ;; note for the future: editorconfig is awesome.
  (setq sh-basic-offset 2)

  ;; todo: find evil package that only removes whitespace on lines you entered in insert mode
  )

(defun neeasade/dashdocs()
  (setq neeasade-dashdocs t)

  (use-package counsel-dash
	:config
    (setq helm-dash-docsets-path (concat user-emacs-directory "docsets"))
    (setq helm-dash-browser-func 'neeasade/eww-browse-existing-or-new)
    )

  ;; todo: this needs a counsel-dash-at-point/how to get point
  (neeasade/bind
   "jd" 'counsel-dash
   )

  ;; todo: neeasade/install-dashdoc call hook in right places 
  )

(defun spacemacs/compute-powerline-height ()
  "Return an adjusted powerline height."
  (let ((scale (if (and (boundp 'powerline-scale) powerline-scale)
				   powerline-scale 1)))
    (truncate (* scale (frame-char-height)))))

(defun neeasade/style()
  (interactive)
  ;; nice to have: an xresource theme that doesn't suck
  (use-package base16-theme)
  ;;(use-package ujelly-theme)

  ;; optionally consider https://github.com/tautologyclub/feebleline
  (use-package spaceline
    :config
    (require 'spaceline-config)
    (setq powerline-scale (string-to-number (get-resource "Emacs.powerlinescale")))
    (setq powerline-height (spacemacs/compute-powerline-height))
    (spaceline-spacemacs-theme)
    (spaceline-toggle-minor-modes-off)
    )

  ;; toggles
  ;; (use-package hide-mode-line
  ;;   :config
  ;;   ;; todo: query to see if modeline is set/toggle rather than single toggle for off
  ;;   (neeasade/bind "tm" (lambda () (interactive) (hide-mode-line -1)))
  ;;   )

  (load-theme (intern (get-resource "Emacs.theme")))
  (setq powerline-default-separator (get-resource "Emacs.powerline"))
  (set-face-attribute 'fringe nil :background nil)

  (setq powerline-default-separator (get-resource "emacs.powerline"))

  ;; sync modeline background color?
  ;;(set-face-attribute 'spacemacs-normal-face nil :inherit 'mode-line)

  (set-face-background 'font-lock-comment-face nil)

  ;; todo: make this on all frames, not just current
  (set-frame-parameter (selected-frame) 'internal-border-width
		       (string-to-number (get-resource "st.borderpx")))

  ;; this is only viable if can get it on internal window edges only
  ;; (not right now)
  ;; (fringe-mode (string-to-number (get-resource "st.borderpx")))

  ;; sync w/ term background
  (set-background-color
   (get-resource "*.background"))

  ;; assume softer vertical border by matching comment face
  (set-face-attribute 'vertical-border
		      nil
		      :foreground (face-attribute 'font-lock-comment-face :foreground))

  ;; this doesn't persist across new frames even though the docs say it should
  (set-face-attribute 'fringe nil :background nil)
  (add-hook 'after-make-frame-functions
	    (lambda (frame)
	      (set-face-attribute 'fringe nil :background nil)
	      )
	    )

  ;; set font on current and future
  (set-face-attribute 'default nil :font (get-resource "st.font"))
  (set-frame-font (get-resource "st.font") nil t)

  ;; NO BOLD (set-face-bold-p doesn't cover everything, some fonts use slant and underline as bold...)
  (mapc (lambda (face)
	  (set-face-attribute face nil
			      :weight 'normal
			      :slant 'normal
			      :underline nil
					;:inherit nil
			      ))
	(face-list))

  ;; make whitespace-mode use just basic coloring
  ;;(setq whitespace-style (quote (spaces tabs newline space-mark tab-mark newline-mark)))

  ;; todo: fix this
  (eval-after-load 'whitespace-mode
    ;; (set-face-attribute 'whitespace-space nil :background nil)
	)

  ;; done at end so it has correct font reference
  (spaceline-compile)
  )

(defun neeasade/window-management()
  (use-package zoom
    :config
    ;; width . height
    (setq zoom-size '(0.58 . 0.618))
    (zoom-mode t)
    )
  )

(defun neeasade/org()
  (use-package org
    :config
    ;; todo: look up org-deadline-warn-days variable
    (load-settings
     "org"
     '(
       ;; where
       directory "~/org/projects"
       agenda-files (list org-directory)
       default-notes-file  "~/org/inbox.org"
       default-diary-file  "~/org/diary.org"
       default-habits-file  "~/org/habits.org"

       ;; style
       bullets-bullet-list '("@" "%" ">" ">")
       ellipsis "…"
       startup-indented t
       startup-folded t

       ;; behavior
       todo-keywords
       '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
	 (sequence "WAITING(w@/!)" "INACTIVE(i@/!)" "|" "CANCELLED(c@/!)" "MEETING"))

       blank-before-new-entry '((heading . t) (plainlist-item . nil))
       tag-alist '(
		   ("test" . ?t)
		   ("endtest" . ?e)
		   )

       ;; clock
       clock-x11idle-program-name "x11idle"
       clock-idle-time 10
       clock-sound nil
       pomodoro-play-sounds nil
       pomodoro-keep-killed-pomodoro-time t
       pomodoro-ask-upon-killing nil

       ;; capture
       capture-templates
       '(("t" "todo" entry (file org-default-notes-file)
	  "* TODO %?\n%u\n%a\n" :clock-in t :clock-resume t)

	 ("b" "Blank" entry (file org-default-notes-file)
	  "* %?\n%u")

	 ("m" "Meeting" entry (file org-default-notes-file)
	  "* MEETING with %? :MEETING:\n%t" :clock-in t :clock-resume t)

	 ("d" "Diary" entry (file+datetree org-default-diary-file)
	  "* %?\n%U\n" :clock-in t :clock-resume t)

	 ("D" "Daily Log" entry (file "~/org/daily-log.org")
	  "* %u %?\n*Summary*: \n\n*Problem*: \n\n*Insight*: \n\n*Tomorrow*: " :clock-in t :clock-resume t)

	 ("i" "Idea" entry (file org-default-notes-file)
	  "* %? :IDEA: \n%u" :clock-in t :clock-resume t)

	 ("n" "Next Task" entry (file+headline org-default-notes-file "Tasks")
	  "** NEXT %? \nDEADLINE: %t")
	 )

       ;; current file or any of the agenda-files, max 9 levels deep
       refile-targets '(
			(nil :maxlevel . 9)
			(org-agenda-files :maxlevel . 9)
			)
       )
     )
    )

  (use-package evil-org
    :after org
    :config
    (add-hook 'org-mode-hook 'evil-org-mode)
    (add-hook 'evil-org-mode-hook
	      (lambda ()
		(evil-org-set-key-theme))))

  (defun neeasade/org-open-url()
    (interactive)
    (browse-url (org-entry-get nil "url"))
    )

  (defun neeasade/org-set-active()
    (interactive)
    (org-delete-property-globally "focus")
    (org-set-property "focus" "t")

    (setq org-active-story (org-get-heading t t t t))
    )

  ;; for externals to call into
  (defun neeasade/org-get-active()
    (if (not (bound-and-true-p org-active-story))
	(progn
	  (neeasade/org-goto-focus)
	  (neeasade/org-set-active)
	  )
      org-active-story
      )
    )

  (defun neeasade/org-goto-focus()
    (interactive)
    (neeasade/find-or-open "~/org/notes.org")
    (goto-char (org-find-property "focus"))
    (org-show-context)
    (org-show-subtree)
    (evil-scroll-line-to-center nil)
    )

  (add-hook
   'org-mode-hook
   ;; todo: checking evil-org
   (neeasade/bind-leader-mode
    'org
    "t" 'org-todo
    "T" 'org-show-todo-tree
    "v" 'org-mark-element
    "a" 'org-agenda
    "l" 'evil-org-open-links
    "p" 'org-pomodoro
    "q" 'tp-set-org-userstory
    "f" 'neeasade/org-set-active
    "b" 'neeasade/org-open-url
    )
   )

  (use-package org-pomodoro
    :config
    (defun neeasade/toggle-music(action)
      ;; todo: setup remote mpd and pass and then use that when away
      ;; implies an initial check to see if we are away
      (let ((command (concat (if sys/windows? "mpc" "player.sh") " " action)))
	(shell-command command)
	))

    (add-hook 'org-pomodoro-started-hook
	      (apply-partially #'neeasade/toggle-music "play"))

    (add-hook 'org-pomodoro-break-finished-hook
	      (apply-partially #'neeasade/toggle-music "play"))

    (add-hook 'org-pomodoro-finished-hook
	      (apply-partially #'neeasade/toggle-music "pause"))
    )
  
  (neeasade/bind
   "jo" (lambda() (interactive) (neeasade/find-or-open "~/org/notes.org" ))
   "jf" 'neeasade/org-goto-focus
   )
  )

(defun neeasade/clojure()
  (use-package clojure-mode)
  (use-package cider)

  ;; TODO: learn lispyville
  (use-package lispy)

  (neeasade/bind-leader-mode
   'clojure
   "er" 'cider-eval-region
   "ei" 'cider-eval-last-sexp
   "eb" 'cider-evil-file
   )
  )

(defun neeasade/nix()
  (use-package nix-mode)
  )

(defun neeasade/target-process()
  (if enable-tp?
      (load "~/.emacs.d/lisp/targetprocess.el")
    )
  )

;; bindings, ivy, counsel, alerts, which-key
(defun neeasade/interface()
  ;; ref: http://oremacs.com/2016/01/06/ivy-flx/
  ;; (use-package flx)

  (defun dynamic-ivy-height()
    (let (
	  (computed (/ (window-total-size) 2))
	  )
      (setq ivy-height computed)
      (setq ivy-fixed-height-minibuffer computed)
      )
    )

  (dynamic-ivy-height)
  (add-hook 'window-configuration-change-hook 'dynamic-ivy-height)

  (use-package ivy
    :config
    (setq ivy-re-builders-alist
    	  '((ivy-switch-buffer . ivy--regex-plus)
    	    (t . ivy--regex-fuzzy)))

    (setq ivy-initial-inputs-alist nil)
    (ivy-mode 1)
    )

  ;; counsel
  (use-package counsel
    :config
    (setq counsel-grep-base-command "rg -i -M 120 --no-heading --line-number --color never '%s' %s")
    (setq counsel-rg-base-command "rg -i -M 120 --no-heading --line-number --color never %s .")
    (setq counsel-ag-base-command "ag --vimgrep --nocolor --nogroup %s")
    )

  (use-package ranger
    :init
    (setq ranger-override-dired t)
    :config
    (setq ranger-show-literal nil
	  ranger-show-hidden t
	  )
    
    (neeasade/bind
     "d" 'deer
     )
    )

  (neeasade/bind
   "'"   'shell-pop
   "/"   'counsel-rg
   "TAB" '(switch-to-other-buffer :which-key "prev buffer")
   "SPC" 'counsel-M-x

   ;; windows
   "w" '(:ignore t :which-key "Windows")
   "wh" 'evil-window-left
   "wj" 'evil-window-down
   "wk" 'evil-window-up
   "wl" 'evil-window-right
   "wd" 'evil-window-delete
   "ww" 'other-window
   ;; window max
   "wm" 'delete-other-windows ;; window-max
   "wo" 'other-frame

   ;; Applications
   "a" '(:ignore t :which-key "Applications")
   "ar" 'ranger
   "ad" 'dired

   "b" '(:ignore t :which-key "Buffers")
   "bd" '(kill-buffer nil)
   "bs" '(switch-to-buffer (get-buffer-create "*scratch*"))
   )

  (use-package alert
    :config (setq alert-default-style
		  (if sys/windows?
		      'toaster
		    'libnotify
		    )))

  (use-package which-key
    :config
    (setq
     which-key-sort-order 'which-key-key-order-alpha
     which-key-idle-delay 0.4
     which-key-side-window-max-width 0.33
     )
    ;; (which-key-setup-side-window-right-bottom)
    )
  )

;; TODO: figure out mpd integration here
(defun neeasade/emms()
  (use-package emms)
  )

(defun neeasade/projectile()
  (use-package projectile)
  ;; (project-find-file-in)
  (neeasade/bind

   "p" '(:ignore t :which-key "projects")
   "pf" 'counsel-git
   ;; "ad" 'dired
   )
  )

(defun neeasade/javascript()
  (defun js-jsx-indent-line-align-closing-bracket ()
    "Workaround sgml-mode and align closing bracket with opening bracket"
    (save-excursion
      (beginning-of-line)
      (when (looking-at-p "^ +\/?> *$")
	(delete-char sgml-basic-offset))))
  (advice-add #'js-jsx-indent-line :after #'js-jsx-indent-line-align-closing-bracket)

  ;; use web-mode for .js files
  (add-to-list 'auto-mode-alist '("\\.js$" . web-mode))

  (use-package rjsx-mode)
  (use-package web-mode
    :config
    (add-hook 'web-mode-hook
	      (lambda ()
		;; short circuit js mode and just do everything in jsx-mode
		(if (equal web-mode-content-type "javascript")
		    (web-mode-set-content-type "jsx")
		  (message "now set to: %s" web-mode-content-type))))

    )

  (use-package nodejs-repl
      ;; todo: check for babel-repl existing and use that
      ;; (doesn't appear to work)
      ;; :init (setq nodejs-repl-command "babel-repl")

      :config
    (neeasade/bind-leader-mode
     'nodejs-repl
     "er "'nodejs-repl-send-region
     "eb" 'nodejs-repl-load-file
     "ee" 'nodejs-repl-send-line
     "ei" 'nodejs-repl-send-last-expression
     )
    )
  )

(defun neeasade/typescript()
  (use-package tide
    :config
    (defun setup-tide-mode ()
      (interactive)
      (tide-setup)
      (setq flycheck-check-syntax-automatically '(save mode-enabled))
      (eldoc-mode +1)
      (tide-hl-identifier-mode +1)
	  )

    ;; aligns annotation to the right hand side
    (setq company-tooltip-align-annotations t)

    ;; formats the buffer before saving
    ;; (add-hook 'before-save-hook 'tide-format-before-save)

    (add-hook 'typescript-mode-hook #'setup-tide-mode)
    )
  )

(defun neeasade/csharp()
  (use-package csharp-mode)
  (use-package omnisharp)
  )

(defun neeasade/git()
  (use-package magit
    :config
    (setq magit-repository-directories (list "~/git"))
	;; https://magit.vc/manual/magit/Performance.html
	(if sys/windows?
		(load-settings
		 "magit"
		 '(
		 ;; diff perf
		 diff-highlight-indentation nil
		 diff-highlight-trailing nil
		 diff-paint-whitespace nil
		 diff-highlight-hunk-body nil
		 diff-refine-hunk nil

		 ;; 
		 refresh-status-buffer nil
		   )
		 )

	  ;; don't show diff when committing --
	  ;; means reviewing will have to be purposeful before  
	  (remove-hook 'server-switch-hook 'magit-commit-diff)

	  ;; disable emacs VC 
	  (setq vc-handled-backends nil)

	  ;; todo: consider
	  ;; (setq auto-revert-buffer-list-filter
	  ;; 'magit-auto-revert-repository-buffers-p)
	  )
	)

  (use-package evil-magit
    :config
    (evil-define-key
	evil-magit-state magit-mode-map "?" 'evil-search-backward)
    )

  (use-package git-gutter-fringe
    :config
    (setq git-gutter-fr:side 'right-fringe)
    ;; fails when too many buffers open on windows
    (if sys/linux? (global-git-gutter-mode t))
    )

  (defhydra git-smerge-menu ()
    "
  movement^^^^               merge action^^           other
  ---------------------^^^^  -------------------^^    -----------
  [_n_]^^    next hunk       [_b_] keep base          [_u_] undo
  [_N_/_p_]  prev hunk       [_m_] keep mine          [_r_] refine
  [_j_/_k_]  move up/down    [_a_] keep all           [_q_] quit
  ^^^^                       [_o_] keep other
  ^^^^                       [_c_] keep current
  ^^^^                       [_C_] combine with next"
    ("n" smerge-next)
    ("p" smerge-prev)
    ("N" smerge-prev)
    ("j" evil-next-line)
    ("k" evil-previous-line)
    ("a" smerge-keep-all)
    ("b" smerge-keep-base)
    ("m" smerge-keep-mine)
    ("o" smerge-keep-other)
    ("c" smerge-keep-current)
    ("C" smerge-combine-with-next)
    ("r" smerge-refine)
    ("u" undo-tree-undo)
    ("q" nil :exit t))

  (neeasade/bind
   "g" '(:ignore t :which-key "git")
   "gs" 'magit-status
   "gb" 'magit-blame
   "gl" 'magit-log-current
   "gm" 'git-smerge-menu/body
   )
  )

(defun neeasade/jump()
  (use-package smart-jump
    :config
    (setq dumb-jump-selector 'ivy)
    (setq dumb-jump-force-searcher 'rg)
    (smart-jump-setup-default-registers)
    (neeasade/bind
     "j" '(:ignore t :which-key "Jump")
     "jj" 'smart-jump-go
     "jb" 'smart-jump-back
     )
    )
  )

(defun neeasade/irc()
  (use-package circe
    :config
    (setq circe-network-options
	  `(
	    ("Freenode"
	     :nick "neeasade"
	     :host "irc.freenode.net"
	     :tls t
	     :nickserv-password ,(pass "freenode")
	     :channels (:after-auth "#bspwm")
	     )
	    ("Rizon"
	     :nick "neeasade"
	     :host "irc.rizon.net"
	     :port (6667 . 6697)
	     :tls t
	     :channels (:after-auth "#rice" "#code")
	     :nickserv-password ,(pass "rizon/pass")
	     :nickserv-mask ,(rx bol "NickServ!service@rizon.net" eol)
	     :nickserv-identify-challenge ,(rx bol "This nickname is registered and protected.")
	     :nickserv-identify-command "PRIVMSG NickServ :IDENTIFY {password}"
	     :nickserv-identify-confirmation ,(rx bol "Password accepted - you are now recognized." eol)
	     )
	    ))
    )

  (defun circe-network-connected-p (network)
    "Return non-nil if there's any Circe server-buffer whose `circe-server-netwok' is NETWORK."
    (catch 'return
      (dolist (buffer (circe-server-buffers))
	(with-current-buffer buffer
	  (if (string= network circe-server-network)
	      (throw 'return t))))))

  (defun circe-maybe-connect (network)
    "Connect to NETWORK, but ask user for confirmation if it's already been connected to."
    (interactive "sNetwork: ")
    (if (or (not (circe-network-connected-p network))
	    (y-or-n-p (format "Already connected to %s, reconnect?" network)))
	(circe network)))

  (defun connect-all-irc()
    (interactive)
    (circe-maybe-connect "Freenode")
    (circe-maybe-connect "Rizon")
    )

  ;; channel name in prompt
  (add-hook 'circe-chat-mode-hook 'my-circe-prompt)
  (defun my-circe-prompt ()
    (lui-set-prompt
     (concat (propertize (concat (buffer-name) ">") 'face 'circe-prompt-face) " ")))

  ;; prevent too long pastes/prompt on it:
  (require 'lui-autopaste)
  (add-hook 'circe-channel-mode-hook 'enable-lui-autopaste)

  ;; hide part, join, quit
  (setq circe-reduce-lurker-spam t)

  (setq circe-format-say "{nick:-8s} {body}")

  (load "lui-logging" nil t)
  (setq lui-logging-directory "~/.irc")
  (enable-lui-logging-globally)

  (setq
   lui-time-stamp-position 'right-margin
   lui-time-stamp-format "%H:%M")

  (add-hook 'lui-mode-hook 'my-circe-set-margin)
  (defun my-circe-set-margin ()
    (setq right-margin-width 5))

  ;; fluid width windows
  (setq
   lui-time-stamp-position 'right-margin
   lui-fill-type nil)

  (add-hook 'lui-mode-hook 'my-lui-setup)
  (defun my-lui-setup ()
    (setq
     fringes-outside-margins t
     right-margin-width 5
     word-wrap t
     wrap-prefix "    ")
    (setf (cdr (assoc 'continuation fringe-indicator-alist)) nil)
    )

  (setq lui-highlight-keywords (list "neeasade"))

  (use-package circe-notifications
    :config
    (autoload 'enable-circe-notifications "circe-notifications" nil t)

    (eval-after-load "circe-notifications"
      '(setq circe-notifications-watch-strings
	;; example: '("people" "you" "like" "to" "hear" "from")))
	'("neeasade")))

    (add-hook 'circe-server-connected-hook 'enable-circe-notifications)
    )

  ;; todo: jump list to buffers prefixed with '#'
  (defun neeasade/jump-irc()
    (interactive)
    (ivy-read "channel: "
	      (remove-if-not
	       (lambda (s) (s-match "#.*" s))
	       (mapcar 'buffer-name (buffer-list))
	     )
     :action (lambda (option) (counsel-switch-to-buffer-or-window option)))
    )

  (neeasade/bind
   "ai" 'connect-all-irc
   "ji" 'neeasade/jump-irc
   )
  )

(defun neeasade/pdf()
  (use-package pdf-tools)
  )

(defun neeasade/terraform()
  (use-package terraform-mode)
  )

(defun neeasade/twitter()
  (use-package twittering-mode
      :commands twit
      :init
      (add-hook 'twittering-edit-mode-hook (lambda () (flyspell-mode)))
      :config
      (load-settings
       'twittering
       use-master-password t
       icon-mode t
       use-icon-storage t
       ;; icon-storage-file (concat joe-emacs-temporal-directory "twittering-mode-icons.gz")
       convert-fix-size 52
       initial-timeline-spec-string '(":home")
       edit-skeleton 'inherit-any
       display-remaining t
       timeline-header  ""
       timeline-footer  ""
       status-format "%i  %S, %RT{%FACE[bold]{%S}} %@  %FACE[shadow]{%p%f%L%r}\n%FOLD[        ]{%T}\n"
       )

      ;; set the new bindings
      (bind-keys :map twittering-mode-map
		 ("\\" . hydra-twittering/body)
		 ("q" . twittering-kill-buffer)
		 ("Q" . twittering-edit-mode)
		 ("j" . twittering-goto-next-status)
		 ("k" . twittering-goto-previous-status)
		 ("h" . twittering-switch-to-next-timeline)
		 ("l" . twittering-switch-to-previous-timeline)
		 ("g" . beginning-of-buffer)
		 ("G" . end-of-buffer)
		 ("t" . twittering-update-status-interactive)
		 ("X" . twittering-delete-status)
		 ("RET" . twittering-reply-to-user)
		 ("r" . twittering-native-retweet)
		 ("R" . twittering-organic-retweet)
		 ("d" . twittering-direct-message)
		 ("u" . twittering-current-timeline)
		 ("b" . twittering-favorite)
		 ("B" . twittering-unfavorite)
		 ("f" . twittering-follow)
		 ("F" . twittering-unfollow)
		 ("i" . twittering-view-user-page)
		 ("/" . twittering-search)
		 ("." . twittering-visit-timeline)
		 ("@" . twittering-other-user-timeline)
		 ("T" . twittering-toggle-or-retrieve-replied-statuses)
		 ("o" . twittering-click)
		 ("TAB" . twittering-goto-next-thing)
		 ("<backtab>" . twittering-goto-previous-thing)
		 ("n" . twittering-goto-next-status-of-user)
		 ("p" . twittering-goto-previous-status-of-user)
		 ("SPC" . twittering-scroll-up)
		 ("S-SPC" . twittering-scroll-down)
		 ("y" . twittering-push-uri-onto-kill-ring)
		 ("Y" . twittering-push-tweet-onto-kill-ring)
		 ("a" . twittering-toggle-activate-buffer)))

  (defhydra hydra-twittering (:color blue :hint nil)
    "
								    ╭────────────┐
     Tweets                User                        Timeline     │ Twittering │
  ╭─────────────────────────────────────────────────────────────────┴────────────╯
    _k_  [_t_] post tweet      _p_  [_f_] follow                  ^_g_^      [_u_] update
    ^↑^  [_X_] delete tweet    ^↑^  [_F_] unfollow              ^_S-SPC_^    [_._] new
    ^ ^  [_r_] retweet         ^ ^  [_d_] direct message          ^^↑^^      [^@^] current user
    ^↓^  [_R_] retweet & edit  ^↓^  [_i_] profile (browser)   _h_ ←   → _l_  [_a_] toggle
    _j_  [_b_] favorite        _n_   ^ ^                          ^^↓^^
    ^ ^  [_B_] unfavorite      ^ ^   ^ ^                         ^_SPC_^
    ^ ^  [_RET_] reply         ^ ^   ^ ^                          ^_G_^
    ^ ^  [_T_] show Thread
    ^ ^  [_y_] yank url          Items                     Do
    ^ ^  [_Y_] yank tweet     ╭───────────────────────────────────────────────────────
    ^ ^  [_e_] edit mode        _<backtab>_ ← _o_pen → _<tab>_    [_q_] exit
    ^ ^   ^ ^                   ^         ^   ^ ^      ^     ^    [_/_] search
  --------------------------------------------------------------------------------
       "
    ("\\" hydra-master/body "back")
    ("<ESC>" nil "quit")
    ("q"          twittering-kill-buffer)
    ("e"          twittering-edit-mode)
    ("j"          twittering-goto-next-status :color red)
    ("k"          twittering-goto-previous-status :color red)
    ("h"          twittering-switch-to-next-timeline :color red)
    ("l"          twittering-switch-to-previous-timeline :color red)
    ("g"          beginning-of-buffer)
    ("G"          end-of-buffer)
    ("t"          twittering-update-status-interactive)
    ("X"          twittering-delete-status)
    ("RET"        twittering-reply-to-user)
    ("r"          twittering-native-retweet)
    ("R"          twittering-organic-retweet)
    ("d"          twittering-direct-message)
    ("u"          twittering-current-timeline)
    ("b"          twittering-favorite)
    ("B"          twittering-unfavorite)
    ("f"          twittering-follow)
    ("F"          twittering-unfollow)
    ("i"          twittering-view-user-page)
    ("/"          twittering-search)
    ("."          twittering-visit-timeline)
    ("@"          twittering-other-user-timeline)
    ("T"          twittering-toggle-or-retrieve-replied-statuses)
    ("o"          twittering-click)
    ("<tab>"      twittering-goto-next-thing :color red)
    ("<backtab>"  twittering-goto-previous-thing :color red)
    ("n"          twittering-goto-next-status-of-user :color red)
    ("p"          twittering-goto-previous-status-of-user :color red)
    ("SPC"        twittering-scroll-up :color red)
    ("S-SPC"      twittering-scroll-down :color red)
    ("y"          twittering-push-uri-onto-kill-ring)
    ("Y"          twittering-push-tweet-onto-kill-ring)
    ("a"          twittering-toggle-activate-buffer))

  ;; todo here: binding to jump to twittering buffer/launch "at"
  )

(defun neeasade/slack()
  (use-package slack
      :commands (slack-start)
      :init
      (setq slack-buffer-emojify t)
      (setq slack-prefer-current-team t)

      :config
      ;; TODO: check this windows only
      ;; https://github.com/yuya373/emacs-slack/issues/161
      (setq request-backend 'url-retrieve)
      (setq slack-request-timeout 50)

      (slack-register-team
       :name (pass "slackteam")
       :default t
       :client-id (pass "slackid")
       :client-secret (pass "slack")
       :token (pass "slacktoken")
       :subscribed-channels '(general random)
       :full-and-display-names t
       )
      )

  ;; todo: where is slack-info/context for this bind
  (neeasade/bind-leader-mode
   'slack-info
   "u" 'slack-room-update-messages)

  (neeasade/bind-leader-mode
   'slack
   "c" 'slack-buffer-kill
   "ra" 'slack-message-add-reaction
   "rr" 'slack-message-remove-reaction
   "rs" 'slack-message-show-reaction-users
   "pl" 'slack-room-pins-list
   "pa" 'slack-message-pins-add
   "pr" 'slack-message-pins-remove
   "mm" 'slack-message-write-another-buffer
   "me" 'slack-message-edit
   "md" 'slack-message-delete
   "u" 'slack-room-update-messages
   "2" 'slack-message-embed-mention
   "3" 'slack-message-embed-channel
   )
  ;; todo: something for these maybe
  ;; "\C-n" 'slack-buffer-goto-next-message
  ;; "\C-p" 'slack-buffer-goto-prev-message)

  (neeasade/bind-leader-mode
   'slack-edit-message
   "k" 'slack-message-cancel-edit
   "s" 'slack-message-send-from-buffer
   "2" 'slack-message-embed-mention
   "3" 'slack-message-embed-channel
   )

  (neeasade/bind
   "as" 'slack-start)
  )

(defun neeasade/email()
  ;; TODO
  )

(defun neeasade/shell()
  (if sys/windows?
      (progn
	(setq shell-file-name
	      (concat (getenv "USERPROFILE")
		      "\\scoop\\apps\\git-with-openssh\\current\\usr\\bin\\bash.exe"
		      ))

	(setq explicit-bash.exe-args '("--login" "-i"))
	)
    )

  (use-package shx :config (shx-global-mode 1))

  (use-package shell-pop
    :config
    (setq shell-pop-window-position "top")
    )

  (neeasade/bind-mode '(shell)
		      "d" 'deer
		      )

  ;; todo: These binds don't work why
  ;; todo: def advice after quite ranger last history shell-pop/use same shell
  ;; (progn ranger-history-ring)
  (neeasade/bind-mode
   '(ranger)
   "s" 'shell-pop
   )

  (general-define-key
   :states '(visual normal)
   :keymaps '(ranger)
   "s" 'shell-pop
   )
  )

(defun neeasade/eshell()
  ;; todo: https://www.reddit.com/r/emacs/comments/6y3q4k/yes_eshell_is_my_main_shell/
  )

(defun neeasade/jekyll()
  (use-package jekyll-modes)
  )

(defun neeasade/autohotkey()
  (use-package xahk-mode)
  )

(defun neeasade/markdown()
  ;; (use-package markdownmode)
  )

(defun neeasade/restclient()
  (use-package restclient
    :config
    (neeasade/bind-leader-mode
     'restclient
     "ei" 'restclient-http-send-current-stay-in-window
     )
    )

  (use-package company-restclient)
  )

(defun neeasade/sql()
  ;; todo 
  )

(defun neeasade/plantuml()
  (use-package plantuml)
  (use-package flycheck-plantuml)
  )

(defun neeasade/ledger()
  (use-package ledger-mode)
  (use-package flycheck-ledger)
  (use-package evil-ledger
    :config
    (add-hook 'ledger-mode-hook #'evil-ledger-mode)
    )
  )

(provide 'theworld)

;;; theworld.el ends here
