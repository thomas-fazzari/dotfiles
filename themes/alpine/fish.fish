set -g fish_color_normal D2DCE8
set -g fish_color_command 7CC2FD
set -g fish_color_keyword B5A7F5
set -g fish_color_param D2DCE8
set -g fish_color_option D2DCE8
set -g fish_color_valid_path --underline
set -g fish_color_quote 95DEAE
set -g fish_color_escape 97CFDD
set -g fish_color_operator 97CFDD
set -g fish_color_redirection 97CFDD
set -g fish_color_end 97CFDD
set -g fish_color_comment 506072 --italics
set -g fish_color_error EC918E
set -g fish_color_autosuggestion 506072
set -g fish_color_selection --background=2c3641
set -g fish_color_search_match --background=2f455d
set -g fish_pager_color_prefix 7BD3E9
set -g fish_pager_color_completion D2DCE8
set -g fish_pager_color_description 8494A6
set -g fish_pager_color_progress 8494A6
set -g fish_pager_color_selected_background --background=2c3641

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#2c3641,bg:-1,spinner:#96DCE0,hl:#7BD3E9' \
    '--color=fg:#D2DCE8,header:#D2DCE8,info:#8494A6,pointer:#7CC2FD' \
    '--color=marker:#ECCD8C,fg+:#D2DCE8,prompt:#96DCE0,hl+:#7BD3E9'
