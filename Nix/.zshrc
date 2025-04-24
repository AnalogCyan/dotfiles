# =============================================================================
#  Core Configuration
# =============================================================================

# Detect OS for platform-specific configurations
if [[ "$(uname)" == "Darwin" ]]; then
  export MACOS=true
else
  export MACOS=false
fi

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

# Node.js cache
export NODE_COMPILE_CACHE=~/.cache/nodejs-compile-cache

# Environment Paths
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Add VSCode to path based on platform
if [[ "$MACOS" == true ]]; then
  # macOS VSCode path
  [[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] &&
    export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
else
  # Linux VSCode path
  [[ -d "$HOME/.vscode/bin" ]] && export PATH="$HOME/.vscode/bin:$PATH"
fi

# Use XDG_DATA_HOME for tool-specific paths when possible
export PATH="${XDG_DATA_HOME}/codeium/bin:$PATH"

# Session Editor
export EDITOR='vim'

# =============================================================================
#  Shell Configuration
# =============================================================================

# Initialize completion system before Antidote
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# History configuration
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory
setopt histignorealldups
setopt histignorespace
setopt sharehistory
setopt incappendhistory
setopt extendedhistory

# Ensure history directory exists
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"

# =============================================================================
#  Tool Initializations
# =============================================================================

# Initialize modern tools
command -v thefuck >/dev/null && eval $(thefuck --alias 2>/dev/null)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Load fzf if it exists
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Initialize Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# iTerm2 Integration (enable whenever detected, including SSH connections)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# 1Password CLI plugins
source ~/.config/op/plugins.sh

# Additional configurations
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# =============================================================================
#  Plugin Management (Antidote)
# =============================================================================

# Initialize Antidote from git installation
if [[ ! -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
  echo "Antidote not found. Installing it from GitHub..."
  if command -v git >/dev/null; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}/.antidote"
  else
    echo "Git not found. Please install git and then Antidote manually."
  fi
fi

# Source Antidote if installed
if [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
else
  echo "Antidote not available. Plugin management disabled."
fi

# Only load plugins if Antidote was sourced
if command -v antidote >/dev/null; then
  antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh
  source ~/.zsh_plugins.zsh

  # Plugin configuration
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"
  # Enable history substring search key bindings
  bindkey '^[[A' history-substring-search-up   # Up Arrow
  bindkey '^[[B' history-substring-search-down # Down Arrow
fi

# Custom completion paths
fpath=(~/.zsh.d/ $fpath)

# Set completion options after plugins are loaded
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# =============================================================================
#  Aliases
# =============================================================================

# btop alias
command -v btop >/dev/null && {
  alias top='btop'
  alias htop='btop'
}

# safer rm alias
rm() {
  if command -v trash >/dev/null; then
    local non_flag_args=()
    for arg in "$@"; do
      if [[ "$arg" != -* ]]; then
        non_flag_args+=("$arg")
      fi
    done
    trash "${non_flag_args[@]}"
  else
    local has_interactive=0
    local args=()
    for arg in "$@"; do
      if [[ "$arg" == -* && "$arg" == *i* ]]; then
        has_interactive=1
      fi
      args+=("$arg")
    done
    if [[ $has_interactive -eq 0 ]]; then
      args=("-i" "${args[@]}")
    fi
    command rm "${args[@]}"
  fi
}

# bat alias
command -v bat >/dev/null && {
  alias cat='bat'
  alias less='bat'
}

# =============================================================================
#  Custom Functions
# =============================================================================

# Load all custom functions
for func in $HOME/.config/zsh/functions/*.zsh; do
  source "$func"
done

# Display greeting on shell start
command -v zsh_greeting >/dev/null && zsh_greeting
