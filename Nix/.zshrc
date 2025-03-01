# =============================================================================
#  Core Configuration
# =============================================================================

# Environment Paths
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
# Use XDG_DATA_HOME for tool-specific paths when possible
export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/codeium/bin:$PATH"

# Session Editor
export EDITOR='vim'

# =============================================================================
#  Plugin Management (Antidote)
# =============================================================================

# Initialize Antidote
source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh" 2>/dev/null || source "$HOME/.antidote/antidote.zsh"
antidote load ~/.zsh_plugins.txt

# =============================================================================
#  Shell Configuration
# =============================================================================

# Set completion options
autoload -Uz compinit
compinit -d ~/.zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt histignorealldups
setopt histignorespace

# Plugin configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"

# Custom completion paths
fpath=(~/.zsh.d/ $fpath)

# =============================================================================
#  Tool Initializations
# =============================================================================

# Initialize modern tools
eval $(thefuck --alias 2>/dev/null)
eval "$(zoxide init zsh)"

# Load fzf if it exists
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Initialize Starship prompt
eval "$(starship init zsh)"

# iTerm2 Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Additional configurations
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# =============================================================================
#  Aliases
# =============================================================================

# System monitoring
alias top='btop'
alias htop='btop'

# =============================================================================
#  Custom Functions
# =============================================================================

# Load all custom functions
for func in $HOME/.config/zsh/functions/*.zsh; do
  source "$func"
done

# Display greeting on shell start
zsh_greeting
