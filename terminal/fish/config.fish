set -q DOTFILES; or set -g DOTFILES (path resolve (status filename) | path dirname | path dirname | path dirname)

# Environment
set -gx DOTNET_CLI_TELEMETRY_OPTOUT true
set -gx PI_CACHE_RETENTION long
# delta reads BAT_THEME too
set -gx BAT_THEME current
set -gx EZA_CONFIG_DIR ~/.config/eza

# PATH: later calls are prepended in front of earlier ones
if test -d /opt/homebrew
    set -gx TERMINAL /Applications/Ghostty.app/Contents/MacOS/ghostty

    # Homebrew (static `brew shellenv`, avoids spawning brew on every start)
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew

    fish_add_path -gmP /opt/homebrew/bin /opt/homebrew/sbin
else
    set -gx TERMINAL ghostty
end
fish_add_path -gP ~/go/bin ~/.local/bin ~/.cargo/bin

status is-interactive; or return

set -g fish_greeting

# Abbreviations
abbr -a ll 'eza -la --git --icons --group-directories-first'
abbr -a la 'eza -a --icons --group-directories-first'
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

source $DOTFILES/themes/current/fish.fish

zoxide init fish --cmd cd | source

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border' $fzf_theme_opts
fzf --fish | source

# mise activates itself through Homebrew's vendor_conf.d on macOS
test -d /opt/homebrew; or mise activate fish | source

# Prompt: past prompts collapse to the prompt char
function starship_transient_prompt_func
    starship module character $argv
end
starship init fish | source
enable_transience

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
