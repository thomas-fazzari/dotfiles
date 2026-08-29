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
export PODMAN_COMPOSE_PROVIDER="podman-compose"
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
ZSH_HIGHLIGHT_STYLES[default]='fg=#A8A49D'
ZSH_HIGHLIGHT_STYLES[command]='fg=#FF6B8B,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#E75A7C,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#FF6B8B,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#FF6B8B,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#79EAF2'
ZSH_HIGHLIGHT_STYLES[single - quoted - argument]='fg=#84D0B7'
ZSH_HIGHLIGHT_STYLES[double - quoted - argument]='fg=#84D0B7'
ZSH_HIGHLIGHT_STYLES[dollar - quoted - argument]='fg=#84D0B7'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#71798A,italic'

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
    --color=bg+:#121E35,bg:#070B11,spinner:#79EAF2,hl:#FF2D6F
    --color=fg:#A8A49D,header:#E6ECFF,info:#8891A5,pointer:#FF2D6F
    --color=marker:#E5BA6F,fg+:#E6ECFF,prompt:#79EAF2,hl+:#FF6B8B
  "
fi

# Cache OMP completion and refresh in background if missing (slow to generate)
if command -v omp >/dev/null 2>&1; then
	omp_completion="${XDG_CACHE_HOME:-$HOME/.cache}/omp/completions.zsh"

	if [[ -r "$omp_completion" ]]; then
		source "$omp_completion"
	else
		{ mkdir -p "${omp_completion:h}" && omp completions zsh >|"$omp_completion"; } >/dev/null 2>&1 &|
	fi

	omp-completions-refresh() {
		mkdir -p "${omp_completion:h}" && omp completions zsh >|"$omp_completion"
	}
fi

if [[ -f "$HOME/.prime/agent/.env" ]]; then
	set -a
	source "$HOME/.prime/agent/.env"
	set +a
fi
