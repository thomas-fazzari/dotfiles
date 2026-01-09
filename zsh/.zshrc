export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
DOTFILES="$HOME/Dev/dotfiles"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

source $ZSH/oh-my-zsh.sh

# SHELL OPTIONS
setopt AUTO_CD

# ALIASES
alias reload='. ~/.zshrc'

# Source alias files
if [ -f "$DOTFILES/zsh/aliases/docker.zsh" ]; then
    source "$DOTFILES/zsh/aliases/docker.zsh"
fi

if [ -f "$DOTFILES/zsh/aliases/rust.zsh" ]; then
    source "$DOTFILES/zsh/aliases/rust.zsh"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
