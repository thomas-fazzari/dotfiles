set -g fish_color_normal C0CAF5
set -g fish_color_command 7AA2F7
set -g fish_color_keyword BB9AF7
set -g fish_color_param C0CAF5
set -g fish_color_option C0CAF5
set -g fish_color_valid_path --underline
set -g fish_color_quote 9ECE6A
set -g fish_color_escape 89DDFF
set -g fish_color_operator 89DDFF
set -g fish_color_redirection 89DDFF
set -g fish_color_end 89DDFF
set -g fish_color_comment 414868 --italics
set -g fish_color_error F7768E
set -g fish_color_autosuggestion 414868
set -g fish_color_selection --background=292E42
set -g fish_color_search_match --background=283457
set -g fish_pager_color_prefix 2AC3DE
set -g fish_pager_color_completion C0CAF5
set -g fish_pager_color_description 737AA2
set -g fish_pager_color_progress 737AA2
set -g fish_pager_color_selected_background --background=292E42

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#292E42,bg:-1,spinner:#7DCFFF,hl:#2AC3DE' \
    '--color=fg:#C0CAF5,header:#C0CAF5,info:#737AA2,pointer:#7AA2F7' \
    '--color=marker:#E0AF68,fg+:#C0CAF5,prompt:#7DCFFF,hl+:#2AC3DE'
