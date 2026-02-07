export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
DOTFILES="$HOME/Dev/dotfiles"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)

source "$ZSH/oh-my-zsh.sh"

# Shell options
setopt AUTO_CD EXTENDED_GLOB

# Aliases
alias reload='. ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'
alias la='ls -A'
alias c='clear'

# Source alias files
for f in "$DOTFILES"/zsh/aliases/*.zsh; do
  [[ -f "$f" ]] && source "$f"
done

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"

# Go
export PATH="$HOME/go/bin:$PATH"

# .NET
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"

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
  unset -f pyenv python python3
  command -v pyenv >/dev/null && eval "$(pyenv init -)"
}
pyenv() { _lazy_pyenv && pyenv "$@"; }
python() { _lazy_pyenv && python "$@"; }
python3() { _lazy_pyenv && python3 "$@"; }

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
