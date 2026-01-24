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

# Skip slow operations when VSCode is resolving shell env
if [[ -z "$VSCODE_RESOLVING_ENVIRONMENT" ]]; then
  # NVM
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

  # Bun completions
  [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

  # pyenv
  command -v pyenv >/dev/null && eval "$(pyenv init -)"

  # uv completions
  fpath=(~/.zfunc $fpath)
  autoload -Uz compinit && compinit

  # SDKMAN
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
