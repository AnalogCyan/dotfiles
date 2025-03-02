# =============================================================================
#  Core Configuration
# =============================================================================

# Detect OS for platform-specific configurations
if [[ "$(uname)" == "Darwin" ]]; then
  export MACOS=true
else
  export MACOS=false
fi

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
export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/codeium/bin:$PATH"

# Session Editor
export EDITOR='vim'

# =============================================================================
#  Shell Configuration
# =============================================================================

# Initialize completion system before Antidote
autoload -Uz compinit
compinit -d ~/.zcompdump

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt histignorealldups
setopt histignorespace

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

# Additional configurations
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# =============================================================================
#  Plugin Management (Antidote)
# =============================================================================

# Initialize Antidote based on platform
if [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
  # Git installation of Antidote (Linux default)
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
elif [[ "$MACOS" == true && -f "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" ]]; then
  # macOS Homebrew location
  source "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
elif [[ -f "/usr/local/share/antidote/antidote.zsh" ]]; then
  # Linux package manager or x86 Homebrew location
  source "/usr/local/share/antidote/antidote.zsh"
else
  echo "Antidote not found. Install it for ZSH plugin management."
fi

# Only load plugins if Antidote was sourced
if command -v antidote >/dev/null; then
  antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh
  source ~/.zsh_plugins.zsh

  # Plugin configuration
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"
fi

# Custom completion paths
fpath=(~/.zsh.d/ $fpath)

# Set completion options after plugins are loaded
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# =============================================================================
#  Aliases
# =============================================================================

# System monitoring
command -v btop >/dev/null && {
  alias top='btop'
  alias htop='btop'
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
