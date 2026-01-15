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

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Bun
export BUN_INSTALL="$HOME/.bun"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"

# uv
fpath=(~/.zfunc $fpath)
autoload -Uz compinit && compinit

# Nim
export NIMBLE_DIR="$HOME/.nimble"
export PATH="$NIMBLE_DIR/bin:$HOME/.cargo/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
