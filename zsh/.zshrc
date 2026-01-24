export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
DOTFILES="$HOME/Dev/dotfiles"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

source $ZSH/oh-my-zsh.sh

# SHELL OPTIONS
setopt AUTO_CD

# ALIASES
alias reload='. ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'
alias la='ls -A'
alias c='clear'

# Source alias files
if [ -f "$DOTFILES/zsh/aliases/docker.zsh" ]; then
    source "$DOTFILES/zsh/aliases/docker.zsh"
fi

if [ -f "$DOTFILES/zsh/aliases/rust.zsh" ]; then
    source "$DOTFILES/zsh/aliases/rust.zsh"
fi

if [ -f "$DOTFILES/zsh/aliases/java.zsh" ]; then
    source "$DOTFILES/zsh/aliases/java.zsh"
fi

# Bun
export BUN_INSTALL="$HOME/.bun"

# Nim
export NIMBLE_DIR="$HOME/.nimble"
export PATH="$NIMBLE_DIR/bin:$HOME/.cargo/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"

# Go
export PATH="$HOME/go/bin:$PATH"

# .NET
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
export PATH="$HOME/.dotnet/tools:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"

# Lazy loading slow tools
_lazy_nvm() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
}
nvm() { _lazy_nvm && nvm "$@"; }
node() { _lazy_nvm && node "$@"; }
npm() { _lazy_nvm && npm "$@"; }
npx() { _lazy_nvm && npx "$@"; }

_lazy_pyenv() {
  unset -f pyenv
  command -v pyenv >/dev/null && eval "$(pyenv init -)"
}
pyenv() { _lazy_pyenv && pyenv "$@"; }

_lazy_sdk() {
  unset -f sdk
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
}
sdk() { _lazy_sdk && sdk "$@"; }

# Cached completions
fpath=(~/.zfunc $fpath)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
