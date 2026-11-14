set -g fish_color_normal E2E4F6
set -g fish_color_command B4C2FF
set -g fish_color_keyword 82AAF5
set -g fish_color_param E2E4F6
set -g fish_color_option F2D4AA
set -g fish_color_valid_path --underline
set -g fish_color_quote C2D68A
set -g fish_color_escape C0A2FF
set -g fish_color_operator 9095BD
set -g fish_color_redirection 9095BD
set -g fish_color_end 9095BD
set -g fish_color_comment 6B70A8 --italics
set -g fish_color_error E87A88
set -g fish_color_autosuggestion 5D6290
set -g fish_color_selection --background=2E2B58
set -g fish_color_search_match --background=2E2B58
set -g fish_pager_color_prefix C2525D
set -g fish_pager_color_completion E2E4F6
set -g fish_pager_color_description 9095BD
set -g fish_pager_color_progress 9095BD
set -g fish_pager_color_selected_background --background=24224A

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#24224A,bg:-1,spinner:#C0A2FF,hl:#C2525D' \
    '--color=fg:#E2E4F6,header:#FFB98A,info:#9095BD,pointer:#C2525D' \
    '--color=marker:#FFB98A,fg+:#F0F1FB,prompt:#82AAF5,hl+:#E87A88'
