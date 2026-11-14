set -g fish_color_normal C6C8D1
set -g fish_color_command 84A0C6
set -g fish_color_keyword A093C7
set -g fish_color_param C6C8D1
set -g fish_color_option 9FA3B8
set -g fish_color_valid_path --underline
set -g fish_color_quote 89B8C2
set -g fish_color_escape E2A478
set -g fish_color_operator 84A0C6
set -g fish_color_redirection A093C7
set -g fish_color_end A093C7
set -g fish_color_comment 6B7089 --italics
set -g fish_color_error E27878
set -g fish_color_autosuggestion 444B71
set -g fish_color_selection --background=272C42
set -g fish_color_search_match --background=3D425B
set -g fish_pager_color_prefix E2A478
set -g fish_pager_color_completion C6C8D1
set -g fish_pager_color_description 6B7089
set -g fish_pager_color_progress 6B7089
set -g fish_pager_color_selected_background --background=1A1C22

# Appended to FZF_DEFAULT_OPTS
set -g fzf_theme_opts \
    '--color=bg+:#1A1C22,bg:-1,spinner:#E2A478,hl:#E2A478' \
    '--color=fg:#C6C8D1,header:#C6C8D1,info:#6B7089,pointer:#E2A478' \
    '--color=marker:#89B8C2,fg+:#C6C8D1,prompt:#84A0C6,hl+:#E2A478'
