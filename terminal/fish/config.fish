set -q DOTFILES; or set -g DOTFILES (path resolve (status filename) | path dirname | path dirname | path dirname)

# Environment
set -gx DOTNET_CLI_TELEMETRY_OPTOUT true
set -gx PI_CACHE_RETENTION long

# PATH: later calls are prepended in front of earlier ones
if test -d /opt/homebrew
    set -gx TERMINAL /Applications/Ghostty.app/Contents/MacOS/ghostty

    # Homebrew (static `brew shellenv`, avoids spawning brew on every start)
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew

    fish_add_path -gmP /opt/homebrew/bin /opt/homebrew/sbin
    fish_add_path -gP $DOTFILES/macos/bin
else
    set -gx TERMINAL ghostty
end
fish_add_path -gP ~/go/bin ~/.local/bin ~/.cargo/bin
fish_add_path -gaP ~/.docker/bin

status is-interactive; or return

set -g fish_greeting

# Abbreviations
abbr -a ll 'ls -lah'
abbr -a la 'ls -A'
abbr -a c clear
abbr -a reload 'exec fish'
abbr -a home 'cd ~'
abbr -a dev 'cd ~/Dev'
abbr -a dot 'cd $DOTFILES'
abbr -a desk 'cd ~/Desktop'
abbr -a docs 'cd ~/Documents'
abbr -a dl 'cd ~/Downloads'
abbr -a news eilmeldung
abbr -a lgtm 'mise -C ~/Dev/pi-otlp run lgtm'
abbr -a dotdot --regex '^\.\.+$' --function multicd
if test -d /opt/homebrew
    abbr -a tmp 'cd $TMPDIR'
else
    abbr -a tmp 'cd /tmp'
    abbr -a melonds 'prime-run melonDS'
end

# Syntax highlighting
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

zoxide init fish | source

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
set -gx FZF_DEFAULT_OPTS \
    '--height 40% --layout=reverse --border' \
    '--color=bg+:#2F334D,bg:-1,spinner:#86E1FC,hl:#65BCFF' \
    '--color=fg:#C8D3F5,header:#C8D3F5,info:#737AA2,pointer:#82AAFF' \
    '--color=marker:#FFC777,fg+:#C8D3F5,prompt:#86E1FC,hl+:#65BCFF'
fzf --fish | source

# mise activates itself through Homebrew's vendor_conf.d on macOS
test -d /opt/homebrew; or mise activate fish | source

# Prompt: past prompts collapse to the prompt char
function starship_transient_prompt_func
    starship module character $argv
end
starship init fish | source
enable_transience
