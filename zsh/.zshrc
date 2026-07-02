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

# ══════════════════════════════════════════════════════════════
# Environment
# ══════════════════════════════════════════════════════════════
export DOTNET_ROOT="/usr/local/share/dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT="true"
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"
export PNPM_HOME="$HOME/Library/pnpm"

# ══════════════════════════════════════════════════════════════
# PATH
# ══════════════════════════════════════════════════════════════
typeset -U path PATH
path=(
	"$PNPM_HOME/bin"
	"$HOME/.cargo/bin"
	"$HOME/.local/bin"
	"$HOME/.config/emacs/bin"
	"$HOME/.ameba/bin"
	"$HOME/go/bin"
	"$DOTNET_ROOT"
	"/opt/homebrew/opt/postgresql@18/bin"
	"$HOME/.opam/5.4.1/bin"
	$path
)
[[ -d "$HOME/.dotnet/tools" ]] && path=("$HOME/.dotnet/tools" $path)
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)

# ══════════════════════════════════════════════════════════════
# Shell options
# ══════════════════════════════════════════════════════════════
setopt AUTO_CD EXTENDED_GLOB HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

# ══════════════════════════════════════════════════════════════
# Custom completions
# ══════════════════════════════════════════════════════════════
[[ -d "$HOME/.zfunc" ]] && fpath=("$HOME/.zfunc" $fpath)

source "$ZSH/oh-my-zsh.sh"

# ══════════════════════════════════════════════════════════════
# Syntax highlighting
# ══════════════════════════════════════════════════════════════
ZSH_HIGHLIGHT_STYLES[default]='fg=#dddddd'
ZSH_HIGHLIGHT_STYLES[command]='fg=#569cd6,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#569cd6,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#dcdcaa,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#569cd6,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#9cdcfe'
ZSH_HIGHLIGHT_STYLES["double-quoted-argument"]='fg=#ce9178'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6a9955,italic'

# ══════════════════════════════════════════════════════════════
# Aliases
# ══════════════════════════════════════════════════════════════
alias reload='. ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'
alias la='ls -A'
alias c='clear'
e() {
	local dir="${1:-.}"

	dir="$(cd "$dir" 2>/dev/null && pwd -P)" || return
	EMACS_OPEN_FOLDER="$dir" /Applications/Emacs.app/Contents/MacOS/Emacs \
		--init-directory "$HOME/.config/emacs" \
		--eval '(th/open-folder (getenv "EMACS_OPEN_FOLDER"))' \
		>/dev/null 2>&1 &
}

# Source alias files
for f in "$DOTFILES"/zsh/aliases/*.zsh(N); do
	source "$f"
done

# ══════════════════════════════════════════════════════════════
# Lazy loaders
# ══════════════════════════════════════════════════════════════

_lazy_command_wrappers() {
	local loader="$1"
	shift

	local cmd
	for cmd in "$@"; do
		eval "$cmd() { $loader >/dev/null 2>&1 || true; command $cmd \"\$@\"; }"
	done
}

# nvm
_lazy_nvm() {
	unset -f nvm node npm npx

	local nvm_script=""
	if [[ -s "$NVM_DIR/nvm.sh" ]]; then
		nvm_script="$NVM_DIR/nvm.sh"
	elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
		nvm_script="/opt/homebrew/opt/nvm/nvm.sh"
	fi

	if [[ -n "$nvm_script" ]]; then
		. "$nvm_script"
		return 0
	fi

	return 1
}
nvm() {
	_lazy_nvm || return 127
	nvm "$@"
}
_lazy_command_wrappers _lazy_nvm node npm npx

# pyenv
_lazy_pyenv() {
	unset -f pyenv python python3

	if command -v pyenv >/dev/null 2>&1; then
		eval "$(pyenv init -)"
		return 0
	fi

	return 1
}
pyenv() {
	_lazy_pyenv || return 127
	pyenv "$@"
}
_lazy_command_wrappers _lazy_pyenv python python3

# opam
_lazy_opam() {
	unset -f opam ocaml ocamlfind dune utop ocamlformat ocamllsp

	local init="$HOME/.opam/opam-init/init.zsh"
	if [[ -r "$init" ]]; then
		source "$init" >/dev/null 2>&1
		eval "$(opam env 2>/dev/null)"
		return 0
	fi

	return 1
}
opam() {
	_lazy_opam || return 127
	opam "$@"
}
_lazy_command_wrappers _lazy_opam ocaml ocamlfind dune utop ocamlformat ocamllsp
unset -f _lazy_command_wrappers

# ══════════════════════════════════════════════════════════════
# fzf
# ══════════════════════════════════════════════════════════════
if command -v fzf >/dev/null 2>&1; then
	eval "$(fzf --zsh)"
	export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
	export FZF_DEFAULT_OPTS="
    --height 40% --layout=reverse --border
    --color=bg+:#262b31,bg:#111416,spinner:#4ec9b0,hl:#3794ff
    --color=fg:#dddddd,header:#569cd6,info:#808080,pointer:#c586c0
    --color=marker:#c586c0,fg+:#ffffff,prompt:#3794ff,hl+:#4fc1ff
  "
fi

# ══════════════════════════════════════════════════════════════
# Powerlevel10k
# ══════════════════════════════════════════════════════════════
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(omp completions zsh)"
