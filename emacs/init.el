;;; init.el -*- lexical-binding: t; -*-

(setq native-comp-jit-compilation nil
      native-comp-async-report-warnings-errors 'silent)

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       dashboard
       hl-todo
       modeline
       ophints
       (popup +defaults)
       treemacs
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       file-templates
       fold
       snippets
       (whitespace +guess +trim)

       :emacs
       dired
       electric
       tramp
       undo
       vc

       :checkers
       syntax

       :tools
       (eval +overlay)
       lookup
       (lsp +eglot)
       magit

       :os
       (:if (featurep :system 'macos) macos)

       :lang
       csharp
       emacs-lisp
       fsharp
       json
       markdown
       (ocaml +lsp)
       org
       sh
       yaml

       :config
       (default +bindings +smartparens))
