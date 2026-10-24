set -q DOTFILES; or set -g DOTFILES (path resolve (status filename) | path dirname | path dirname | path dirname)

# Environment
set -gx DOTNET_CLI_TELEMETRY_OPTOUT true
set -gx TERMINAL ghostty

# PATH: later calls are prepended in front of earlier ones
fish_add_path -gP $DOTFILES/bin ~/go/bin ~/.local/bin ~/.cargo/bin

status is-interactive; or return

set -g fish_greeting

# Abbreviations
abbr -a ll 'ls -lah'
abbr -a la 'ls -A'
abbr -a c clear
abbr -a reload 'exec fish'
abbr -a home 'cd ~'
abbr -a dev 'cd ~/dev'
abbr -a dot 'cd $DOTFILES'
abbr -a desk 'cd ~/Desktop'
abbr -a docs 'cd ~/Documents'
abbr -a dl 'cd ~/Downloads'
abbr -a tmp 'cd /tmp'
abbr -a melonds 'prime-run melonDS'
abbr -a dotdot --regex '^\.\.+$' --function multicd

# Syntax highlighting
set -g fish_color_normal A9B1D6
set -g fish_color_command 7AA2F7
set -g fish_color_keyword BB9AF7
set -g fish_color_param A9B1D6
set -g fish_color_option A9B1D6
set -g fish_color_valid_path --underline
set -g fish_color_quote 85D0B7
set -g fish_color_escape 89DDFF
set -g fish_color_operator 89DDFF
set -g fish_color_redirection 89DDFF
set -g fish_color_end 89DDFF
set -g fish_color_comment 444B6A --italics
set -g fish_color_error FF5370
set -g fish_color_autosuggestion 444B6A
set -g fish_color_selection --background=202330
set -g fish_color_search_match --background=1D2847
set -g fish_pager_color_prefix 668AC4
set -g fish_pager_color_completion A9B1D6
set -g fish_pager_color_description 787C99
set -g fish_pager_color_progress 787C99
set -g fish_pager_color_selected_background --background=20222C

# Tool init
command -q zoxide; and zoxide init fish | source

if command -q opam; and test -d ~/.opam
    opam env --shell=fish 2>/dev/null | source
end

# fzf
if command -q fzf
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
    set -gx FZF_DEFAULT_OPTS \
        '--height 40% --layout=reverse --border' \
        '--color=bg+:#202330,bg:#08080B,spinner:#7DCFFF,hl:#668AC4' \
        '--color=fg:#A9B1D6,header:#C0CAF5,info:#787C99,pointer:#7AA2F7' \
        '--color=marker:#E0AF68,fg+:#C0CAF5,prompt:#7DCFFF,hl+:#668AC4'
    fzf --fish | source
end

command -q mise; and mise activate fish | source

# Prompt: past prompts collapse to the prompt char
if command -q starship
    function starship_transient_prompt_func
        starship module character $argv
    end
    starship init fish | source
    enable_transience
end
