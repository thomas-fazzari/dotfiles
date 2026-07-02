;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name "Thomas"
      doom-font (font-spec :family "Menlo" :size 16)
      doom-variable-pitch-font (font-spec :family "Menlo" :size 16)
      doom-theme 'doom-one
      display-line-numbers-type t
      frame-resize-pixelwise t
      org-directory "~/Notes"
      default-directory "~/Dev/")

(dolist (parameter '((width . 125) (height . 38)))
  (add-to-list 'initial-frame-alist parameter)
  (add-to-list 'default-frame-alist parameter))
(add-to-list 'initial-frame-alist '(ns-appearance . dark))
(add-to-list 'default-frame-alist '(ns-appearance . dark))

(defun th/center-frame (&optional frame)
  "Center FRAME on its current monitor."
  (let ((frame (or frame (selected-frame))))
    (when (display-graphic-p frame)
      (let* ((geometry (alist-get 'geometry (frame-monitor-attributes frame)))
             (monitor-left (nth 0 geometry))
             (monitor-top (nth 1 geometry))
             (monitor-width (nth 2 geometry))
             (monitor-height (nth 3 geometry))
             (frame-width (frame-pixel-width frame))
             (frame-height (frame-pixel-height frame))
             (left (+ monitor-left (max 0 (/ (- monitor-width frame-width) 2))))
             (top (+ monitor-top (max 0 (/ (- monitor-height frame-height) 2)))))
        (set-frame-position frame left top)))))

(add-hook 'window-setup-hook #'th/center-frame)
(add-hook 'after-make-frame-functions #'th/center-frame)

(setenv "DOTNET_ROOT" "/usr/local/share/dotnet")

(dolist (dir '("~/.dotnet/tools"
               "~/.opam/5.4.1/bin"
               "/usr/local/share/dotnet"
               "/opt/homebrew/bin"
               "/opt/homebrew/sbin"))
  (let ((expanded (
    expand-file-name dir)))
    (when (file-directory-p expanded)
      (add-to-list 'exec-path expanded)
      (setenv "PATH" (concat expanded path-separator (getenv "PATH"))))))


(after! eglot
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) . ("csharp-ls"))))

(after! treemacs
  (setq treemacs-width 38
        treemacs-width-is-initially-locked nil)
  (define-key treemacs-mode-map [mouse-1] #'treemacs-single-click-expand-action))

(defun th/toggle-project-sidebar ()
  "Toggle the Treemacs project sidebar."
  (interactive)
  (require 'treemacs)
  (treemacs))

(defun th/open-folder (dir)
  "Open DIR as an IDE-like project workspace."
  (interactive "DOpen folder: ")
  (let ((default-directory (file-name-as-directory (expand-file-name dir))))
    (dired default-directory)
    (require 'treemacs)
    (treemacs-add-and-display-current-project-exclusively)))

(map! "C-c p p" #'project-switch-project
      "C-c p f" #'project-find-file
      "C-c p g" #'consult-ripgrep
      "C-c b b" #'consult-buffer
      "C-c g s" #'magit-status
      "C-c l r" #'eglot-rename
      "C-c l f" #'eglot-format
      "C-c l a" #'eglot-code-actions
      "C-c l d" #'flymake-show-buffer-diagnostics
      "C-c o t" #'th/toggle-project-sidebar
      "C-c o p" #'th/open-folder)
