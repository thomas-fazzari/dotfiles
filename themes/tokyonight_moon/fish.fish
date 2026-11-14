set -g fish_color_normal C8D3F5
set -g fish_color_command 82AAFF
set -g fish_color_keyword C099FF
set -g fish_color_param C8D3F5
set -g fish_color_option C8D3F5
set -g fish_color_valid_path --underline
set -g fish_color_quote C3E88D
set -g fish_color_escape 89DDFF
set -g fish_color_operator 89DDFF
set -g fish_color_redirection 89DDFF
set -g fish_color_end 89DDFF
set -g fish_color_comment 444A73 --italics
set -g fish_color_error FF757F
set -g fish_color_autosuggestion 444A73
set -g fish_color_selection --background=2F334D
set -g fish_color_search_match --background=2D3F76
set -g fish_pager_color_prefix 65BCFF
set -g fish_pager_color_completion C8D3F5
set -g fish_pager_color_description 737AA2
set -g fish_pager_color_progress 737AA2
set -g fish_pager_color_selected_background --background=2F334D

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#2F334D,bg:-1,spinner:#86E1FC,hl:#65BCFF' \
    '--color=fg:#C8D3F5,header:#C8D3F5,info:#737AA2,pointer:#82AAFF' \
    '--color=marker:#FFC777,fg+:#C8D3F5,prompt:#86E1FC,hl+:#65BCFF'
