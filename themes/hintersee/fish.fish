set -g fish_color_normal CDE1F2
set -g fish_color_command 67BFF8
set -g fish_color_keyword B5AEFE
set -g fish_color_param CDE1F2
set -g fish_color_option CDE1F2
set -g fish_color_valid_path --underline
set -g fish_color_quote 89EFA0
set -g fish_color_escape 95E9F7
set -g fish_color_operator 95E9F7
set -g fish_color_redirection 95E9F7
set -g fish_color_end 95E9F7
set -g fish_color_comment 4B6174 --italics
set -g fish_color_error FE8A82
set -g fish_color_autosuggestion 4B6174
set -g fish_color_selection --background=293743
set -g fish_color_search_match --background=274660
set -g fish_pager_color_prefix 5BCDF3
set -g fish_pager_color_completion CDE1F2
set -g fish_pager_color_description 7F95A9
set -g fish_pager_color_progress 7F95A9
set -g fish_pager_color_selected_background --background=293743

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#293743,bg:-1,spinner:#96EDF5,hl:#5BCDF3' \
    '--color=fg:#CDE1F2,header:#CDE1F2,info:#7F95A9,pointer:#67BFF8' \
    '--color=marker:#FED58E,fg+:#CDE1F2,prompt:#96EDF5,hl+:#5BCDF3'
