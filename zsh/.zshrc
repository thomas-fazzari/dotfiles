export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
DOTFILES="${DOTFILES:-${${(%):-%N}:A:h:h}}"

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
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# PATH
typeset -U path PATH
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$BUN_INSTALL/bin"
  "$HOME/go/bin"
  "$DOTNET_ROOT"
  "$DOTNET_ROOT/tools"
  "/opt/homebrew/opt/postgresql@18/bin"
  $path
)
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)
[[ -d "$ANDROID_HOME/emulator" ]] && path=("$ANDROID_HOME/emulator" $path)
[[ -d "$ANDROID_HOME/platform-tools" ]] && path=("$ANDROID_HOME/platform-tools" $path)
[[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]] && path=("$ANDROID_HOME/cmdline-tools/latest/bin" $path)

# Shell options
setopt AUTO_CD EXTENDED_GLOB

# Custom completions
[[ -d "$HOME/.zfunc" ]] && fpath=("$HOME/.zfunc" $fpath)

source "$ZSH/oh-my-zsh.sh"

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
nvm() {
  _lazy_nvm || return 127
  nvm "$@"
}
node() {
  _lazy_nvm >/dev/null 2>&1 || true
  command node "$@"
}
npm() {
  _lazy_nvm >/dev/null 2>&1 || true
  command npm "$@"
}
npx() {
  _lazy_nvm >/dev/null 2>&1 || true
  command npx "$@"
}

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
  command pyenv "$@"
}
python() {
  _lazy_pyenv >/dev/null 2>&1 || true
  command python "$@"
}
python3() {
  _lazy_pyenv >/dev/null 2>&1 || true
  command python3 "$@"
}

# Bun completions
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
