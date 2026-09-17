if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
DOTFILES="${DOTFILES:-${${(%):-%N}:A:h:h}}"

plugins=(
	git
	zsh-autosuggestions
	web-search
	zsh-syntax-highlighting
)

# Environment
export DOTNET_CLI_TELEMETRY_OPTOUT="true"
export PYENV_ROOT="$HOME/.pyenv"
export TERMINAL="/Applications/Ghostty.app/Contents/MacOS/ghostty"
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
export PNPM_HOME="$HOME/Library/pnpm"

# PATH
typeset -U path PATH
for dir in \
	"$PNPM_HOME" \
	"$PNPM_HOME/bin" \
	"$HOME/.local/bin" \
	"$HOME/go/bin" \
	"${DOTNET_ROOT:-}" \
	"$HOME/.dotnet/tools" \
	"$PYENV_ROOT/bin"; do
	[[ -n "$dir" && -d "$dir" ]] && path=("$dir" $path)
done

for dir in /opt/homebrew/opt/bun/bin /opt/homebrew/opt/postgresql@18/bin; do
	[[ -d "$dir" ]] && path=("$dir" $path)
done

# Shell options
setopt AUTO_CD EXTENDED_GLOB HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

# Custom completions
[[ -d "$HOME/.zfunc" ]] && fpath=("$HOME/.zfunc" $fpath)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if ! (($+functions[compdef])); then
	autoload -Uz compinit
	compinit -i -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
fi

# Syntax highlighting
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#A9B1D6'
ZSH_HIGHLIGHT_STYLES[command]='fg=#7AA2F7,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#7AA2F7'
ZSH_HIGHLIGHT_STYLES[function]='fg=#7AA2F7'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#BB9AF7'
ZSH_HIGHLIGHT_STYLES[path]='fg=#7DCFFF'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ECE6A'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ECE6A'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#9ECE6A'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#565F89,italic'

# Aliases
alias reload='. ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'
alias la='ls -A'
alias c='clear'
alias home='cd "$HOME"'
alias dev='cd ~/dev'
alias dot='cd "$DOTFILES"'
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias tmp='cd "${TMPDIR:-/tmp}"'
alias which='command -v'
alias code='code-insiders'
e() {
	nvim "${1:-.}"
}

[[ -r "$DOTFILES/zsh/aliases/media.zsh" ]] && source "$DOTFILES/zsh/aliases/media.zsh"

# Tool init
if command -v fnm >/dev/null 2>&1; then
	eval "$(fnm env --use-on-cd --shell zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
	eval "$(zoxide init zsh)"
fi

if command -v pyenv >/dev/null 2>&1; then
	eval "$(pyenv init --no-rehash -)"
fi

if [[ -r "$HOME/.opam/opam-init/init.zsh" ]]; then
	source "$HOME/.opam/opam-init/init.zsh" >/dev/null 2>&1
	eval "$(opam env 2>/dev/null)"
fi

# fzf
if command -v fzf >/dev/null 2>&1; then
	eval "$(fzf --zsh)"
	export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
	export FZF_DEFAULT_OPTS="
    --height 40% --layout=reverse --border
    --color=bg+:#292E42,bg:#16161E,spinner:#7DCFFF,hl:#F7768E
    --color=fg:#A9B1D6,header:#C0CAF5,info:#7B88A1,pointer:#F7768E
    --color=marker:#E0AF68,fg+:#C0CAF5,prompt:#7DCFFF,hl+:#BB9AF7
  "
fi

if [[ -f "$HOME/.prime/agent/.env" ]]; then
	set -a
	source "$HOME/.prime/agent/.env"
	set +a
fi
