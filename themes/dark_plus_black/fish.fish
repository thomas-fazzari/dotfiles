set -g fish_color_normal D4D4D4
set -g fish_color_command DCDCAA
set -g fish_color_keyword C586C0
set -g fish_color_param 9CDCFE
set -g fish_color_option B5CEA8
set -g fish_color_valid_path --underline
set -g fish_color_quote CE9178
set -g fish_color_escape D7BA7D
set -g fish_color_operator D4D4D4
set -g fish_color_redirection D4D4D4
set -g fish_color_end D4D4D4
set -g fish_color_comment 888888 --italics
set -g fish_color_error F44747
set -g fish_color_autosuggestion 666666
set -g fish_color_selection --background=264F78
set -g fish_color_search_match --background=264F78
set -g fish_pager_color_prefix 4FC1FF
set -g fish_pager_color_completion CCCCCC
set -g fish_pager_color_description 8B949E
set -g fish_pager_color_progress 8B949E
set -g fish_pager_color_selected_background --background=323232

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#323232,bg:-1,spinner:#C586C0,hl:#4FC1FF' \
    '--color=fg:#CCCCCC,header:#D7BA7D,info:#8B949E,pointer:#0078D4' \
    '--color=marker:#DCDCAA,fg+:#FFFFFF,prompt:#569CD6,hl+:#4FC1FF'
