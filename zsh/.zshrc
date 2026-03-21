export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
DOTFILES="${DOTFILES:-${${(%):-%N}:A:h:h}}"

source "$DOTFILES/theme/tokyo-night.sh"

plugins=(
  git
  zsh-autosuggestions
  web-search
  zsh-syntax-highlighting
)

# Environment
export BUN_INSTALL="$HOME/.bun"
export DOTNET_ROOT="$HOME/.dotnet"
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"

# PATH
typeset -U path PATH
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$HOME/.ameba/bin"
  "$BUN_INSTALL/bin"
  "$HOME/go/bin"
  "$DOTNET_ROOT"
  "$DOTNET_ROOT/tools"
  "/opt/homebrew/opt/postgresql@18/bin"
  $path
)
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)

# Shell options
setopt AUTO_CD EXTENDED_GLOB HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

# Custom completions
[[ -d "$HOME/.zfunc" ]] && fpath=("$HOME/.zfunc" $fpath)

# Agnoster custom colors
AGNOSTER_CONTEXT_BG="$TN_SURFACE"
AGNOSTER_CONTEXT_FG="$TN_FG"
AGNOSTER_DIR_BG="$TN_SURFACE"
AGNOSTER_DIR_FG="$TN_BLUE"
AGNOSTER_GIT_CLEAN_BG="$TN_GREEN"
AGNOSTER_GIT_CLEAN_FG="$TN_DARK"
AGNOSTER_GIT_DIRTY_BG="$TN_MAGENTA"
AGNOSTER_GIT_DIRTY_FG="$TN_DARK"
AGNOSTER_STATUS_BG="$TN_SURFACE"
AGNOSTER_STATUS_RETVAL_FG="$TN_RED"
AGNOSTER_STATUS_ROOT_FG="$TN_MAGENTA"
AGNOSTER_STATUS_JOB_FG="$TN_CYAN"

source "$ZSH/oh-my-zsh.sh"

ZSH_HIGHLIGHT_STYLES[default]='fg=white'
ZSH_HIGHLIGHT_STYLES[command]="fg=${TN_CYAN},bold"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=${TN_CYAN},bold"
ZSH_HIGHLIGHT_STYLES[function]="fg=${TN_CYAN},bold"
ZSH_HIGHLIGHT_STYLES[alias]="fg=${TN_CYAN},bold"
ZSH_HIGHLIGHT_STYLES[path]="fg=${TN_BLUE}"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=${TN_MAGENTA}"
ZSH_HIGHLIGHT_STYLES[comment]="fg=${TN_COMMENT},italic"

# Aliases
alias reload='. ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'
alias la='ls -A'
alias c='clear'

# Source alias files
for f in "$DOTFILES"/zsh/aliases/*.zsh(N); do
  source "$f"
done

# Lazy loading slow tools
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
nvm() { _lazy_nvm || return 127; nvm "$@" }
node() { _lazy_nvm >/dev/null 2>&1 || true; command node "$@" }
npm() { _lazy_nvm >/dev/null 2>&1 || true; command npm "$@" }
npx() { _lazy_nvm >/dev/null 2>&1 || true; command npx "$@" }

_lazy_pyenv() {
  unset -f pyenv python python3

  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    return 0
  fi

  return 1
}
pyenv() { _lazy_pyenv || return 127; command pyenv "$@" }
python() { _lazy_pyenv >/dev/null 2>&1 || true; command python "$@" }
python3() {
  _lazy_pyenv >/dev/null 2>&1 || true; command python3 "$@" }

# Bun completions
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

