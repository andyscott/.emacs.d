;;; init.el --- Andy's configuration file

(setq debug-on-error t)

(if (version< emacs-version "23.0")
    (error "Old ass Emacs isn't supported"))

;; Turn off mouse interface early in startup to avoid momentary display
(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(setq inhibit-startup-screen t)
(setq initial-scratch-message ";; Weclome to Emacs, Andy")

;;; Code:
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

(add-to-list 'load-path "~/.emacs.d/vendor")

;;;; package.el
(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "https://melpa.org/packages/") t)
(package-initialize)

(defun ensure-packages (&rest packages)
    ; (package-refresh-contents)
    (mapc '(lambda (package)
        (unless
            (package-installed-p package)
            (package-install package)))
        packages))

(ensure-packages
    'ace-window
    'base16-theme
    'bazel-mode
    'beacon
    'company
    'company-lsp
    'cycle-themes
    'doom-modeline
    'editorconfig
    'evil
    'exec-path-from-shell
    'expand-region
    'fireplace
    'flycheck
    'haskell-mode
    'hydra
    'lsp-mode
    'lsp-scala
    'lsp-ui
    'magit
    'multi-term
    'nix-mode
    'outshine
    'python-mode
    'sbt-mode
    'scala-mode
    'smex
    'undo-tree
    'use-package
    'yaml-mode
    )

(use-package yaml-mode)

(use-package bazel-workspace
  :load-path "~/.emacs.d/bazel-workspace")

(cond ((eq system-type 'darwin)
    (when (window-system)
        (mac-auto-operator-composition-mode))
    (setq mac-command-modifier (quote super))
    (setq mac-option-modifier (quote meta))
    (setq mac-function-modifier (quote meta))
    (setq delete-by-moving-to-trash t)
    (setq trash-directory "~/.Trash/")))

(delete-selection-mode 1) ; overwrite regions when typing, pasting, etc
(use-package paren
  :init
  (setq show-paren-delay 0)
  :config
  (show-paren-mode 1))
(when (window-system)
  (set-frame-font "Operator Mono"))
(blink-cursor-mode 1)
(setq-default cursor-type 'bar)
(use-package beacon
  :init
  (setq beacon-blink-when-focused 1)
  :config
  (beacon-mode 1))

(defvar grayson/themes)
(defvar grayson/themes-index)

(setq grayson/themes '(
    base16-rebecca
    base16-harmonic-dark
    base16-grayscale-light
    base16-atelier-sulphurpool-light
    base16-atelier-lakeside))
(setq grayson/themes-index 0)

(defun grayson/theme-next ()
  "Switch to the next theme."
  (interactive)
  (setq grayson/themes-index (% (1+ grayson/themes-index) (length grayson/themes)))
  (grayson/theme-load-indexed)
  (message (symbol-name (nth grayson/themes-index grayson/themes))))

(defun grayson/theme-previous ()
  "Switch to the previous theme."
  (interactive)
  (setq grayson/themes-index (% (+ grayson/themes-index (length grayson/themes) -1) (length grayson/themes)))
  (grayson/theme-load-indexed)
  (message (symbol-name (nth grayson/themes-index grayson/themes))))

(defun grayson/theme-load-indexed ()
  "Set the theme according to the index variable."
  (grayson/theme-try-load (nth grayson/themes-index grayson/themes)))

(defun grayson/theme-try-load (theme)
  "Try to load a given THEME."
  (if (ignore-errors (load-theme theme :no-confirm))
      (mapcar #'disable-theme (remove theme custom-enabled-themes))
    (message "Unable to find theme file for ‘%s’" theme)))

(defvar after-load-theme-hook nil
  "Hook run after a color theme is loaded using `load-theme'.")

(defadvice load-theme (after run-after-load-theme-hook activate)
  "Run `after-load-theme-hook'."
  (message (format "Loading theme %s" (ad-get-arg 0)))
  (run-hooks 'after-load-theme-hook))

(defun grayson/after-theme-update ()
  "Apply after load tweaks for the base 16 themes."
  (let ((current-theme (symbol-name (car custom-enabled-themes))))
    (if (string-prefix-p "base16" current-theme)
	(let* ((description (symbol-value (intern (concat current-theme "-colors"))))
               (theme-colors (cl-loop for (name value) on description by #'cddr
                                      collect (cons name value))))
	  (setq beacon-color (alist-get :base08 theme-colors))
	  (set-face-attribute 'font-lock-comment-face nil :slant 'italic)
	  (set-face-attribute 'show-paren-match nil :background (alist-get :base03 theme-colors))
	  (set-face-attribute 'show-paren-match nil :foreground (alist-get :base0B theme-colors))
	  (set-face-attribute 'trailing-whitespace nil :background (alist-get :base03 theme-colors))
	  (setq ansi-term-color-vector [term term-color-black term-color-red term-color-green term-color-yellow term-color-blue term-color-magenta term-color-cyan term-color-white])))))

(add-hook 'after-load-theme-hook #'grayson/after-theme-update)

(grayson/theme-load-indexed)
(grayson/after-theme-update)

(require 'hydra)
(defhydra grayson-menu (:color pink :hint nil)
  "
_f_: toggle fullscreen
_t_: change theme
"
  ("q" nil)
  ("f" toggle-frame-fullscreen :exit t)
  ("t" grayson-theme-menu/body :exit t))

(defhydra grayson-theme-menu (:color pink :hint nil)
  "
_p_: previous theme
_n_: next theme
"
  ("q" nil)
  ("p" grayson/theme-previous)
  ("n" grayson/theme-next))

(global-set-key (kbd "C-x /") 'grayson-menu/body)

(use-package all-the-icons)
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode))

(use-package winner
    :config
    (winner-mode))

(use-package expand-region
    :config
    (global-set-key (kbd "C-=") 'er/expand-region))

(use-package lsp-ui
    :after (lsp-mode)
    :init
    (add-hook 'lsp-mode-hook 'lsp-ui-mode))

(use-package company-lsp
    :after (company)
    :config
    (push 'company-lsp company-backends))

(use-package ace-window
    :config
    (global-set-key (kbd "C-x o") 'ace-window)
    (setq aw-dispatch-always t)
    (add-to-list 'aw-dispatch-alist '(?u (lambda ()
                  (progn
                    (winner-undo)
                    (setq this-command 'winner-undo)))))
    (add-to-list 'aw-dispatch-alist '(?r winner-redo))

    (when (package-installed-p 'hydra)
      (defhydra hydra-window-size (:color red)

        "Windows size"
        ("h" shrink-window-horizontally "shrink horizontal")
        ("j" shrink-window "shrink vertical")
        ("k" enlarge-window "enlarge vertical")
        ("l" enlarge-window-horizontally "enlarge horizontal"))
      (add-to-list 'aw-dispatch-alist '(?w hydra-window-size/body) t)
      ))

(use-package ibuffer
  :config
  (global-set-key (kbd "C-x b") 'ibuffer)
  (global-set-key (kbd "C-x C-b") 'ibuffer))

(use-package ido
  :init
  (setq ido-enable-flex-matching t)
  (setq ido-everywhere t)
  ;;(setq ido-default-file-method 'selected-window)
  (setq ido-default-buffer-method 'selected-window)
  :config
  (ido-mode 1))

(use-package evil
  :init ;; tweak evil's configuration before loading it
  (setq evil-default-state 'emacs)
  (setq evil-search-module 'evil-search)
  (setq evil-emacs-state-cursor (symbol-value 'cursor-type))
  :config
  (evil-mode 1))

(use-package smex
    :config
    (smex-initialize)
    (global-set-key (kbd "M-x") 'smex)
    (global-set-key (kbd "M-X") 'smex-major-mode-commands)
    ;; old M-x
    (global-set-key (kbd "C-c C-c M-x") 'execute-extended-command))

(use-package undo-tree
    :config
    (global-undo-tree-mode 1))

(use-package editorconfig
    :ensure t
    :config
    (editorconfig-mode 1))

(use-package company
    :hook (after-init-hook . global-company-mode))

(use-package flycheck
    :config
    (global-flycheck-mode))

(use-package exec-path-from-shell
    :config
    (exec-path-from-shell-initialize))

(use-package lsp-scala
  :after scala-mode
  :demand t
  ;; Optional - enable lsp-scala automatically in scala files
  :hook (scala-mode . lsp))

(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map))


(defun smart-beginning-of-line ()
  "Move point to first non-whitespace character or `beginning-of-line'."
  (interactive)
  (let ((oldpos (point)))
    (back-to-indentation)
    (and (= oldpos (point))
         (beginning-of-line))))

(global-set-key "\C-a" 'smart-beginning-of-line)

(setq compilation-scroll-output t)

(let ((file (expand-file-name "init-local.el"
			      (if load-file-name
				  (file-name-directory load-file-name)
				default-directory))))
  (when (file-exists-p file)
    (load-file file)))

(provide 'init)
;;; init.el ends here
