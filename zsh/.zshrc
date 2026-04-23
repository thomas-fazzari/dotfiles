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
export BUN_INSTALL="$HOME/.bun"
export DOTNET_ROOT="/usr/local/share/dotnet"
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

source "$ZSH/oh-my-zsh.sh"

ZSH_HIGHLIGHT_STYLES[default]='fg=white'
ZSH_HIGHLIGHT_STYLES[command]='fg=#8ce0ff,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8ce0ff,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#8ce0ff,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#8ce0ff,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#86abff'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#c8a1ff'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89,italic'

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

# fzf
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  export FZF_DEFAULT_OPTS="
    --height 40% --layout=reverse --border
    --color=bg+:#292e42,bg:#24283b,spinner:#9ece6a,hl:#7aa2f7
    --color=fg:#c0caf5,header:#7aa2f7,info:#7aa2f7,pointer:#ff007c
    --color=marker:#ff007c,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff
  "
fi

# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
