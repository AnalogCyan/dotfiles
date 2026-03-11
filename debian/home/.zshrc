# =============================================================================
#  Core Configuration (Debian)
# =============================================================================

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

# Node.js cache
export NODE_COMPILE_CACHE="$XDG_CACHE_HOME/nodejs-compile-cache"

# Environment Paths
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# VS Code Insiders
[[ -d "/usr/share/code-insiders/bin" ]] && export PATH="/usr/share/code-insiders/bin:$PATH"

# Codeium
export PATH="${XDG_DATA_HOME}/codeium/bin:$PATH"

# Session Editor
if command -v code-insiders >/dev/null 2>&1; then
  export EDITOR='code-insiders --wait -n'
elif command -v code >/dev/null 2>&1; then
  export EDITOR='code --wait -n'
elif command -v hx >/dev/null 2>&1; then
  export EDITOR='hx'
else
  export EDITOR='vim'
fi
export VISUAL="${EDITOR}"
export GIT_EDITOR="${EDITOR}"
export PAGER='less'
export LESS='-R --use-color -M'

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
setopt correct
setopt nobeep

# Ensure history/cache directories exist
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"

# =============================================================================
#  Tool Initializations
# =============================================================================

command -v thefuck >/dev/null && eval "$(thefuck --alias 2>/dev/null)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Load fzf
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Initialize Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# iTerm2 Integration
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

# VS Code Insiders shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code-insiders --locate-shell-integration-path zsh)"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# =============================================================================
#  Plugin Management (Antidote)
# =============================================================================

# Initialize Antidote from git installation
if [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
else
  echo "Antidote not found. Install via: git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote"
fi

# Only load plugins if Antidote was sourced
if command -v antidote >/dev/null; then
  antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh

  # EZA parameters
  typeset -A EZA_PARAMS
  EZA_PARAMS=(
    all   '--icons --git --group-directories-first'
    long  '--icons --git'
    tree  '--tree --icons'
  )

  source ~/.zsh_plugins.zsh

  # Plugin configuration
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# Custom completion paths
fpath=(~/.zsh.d/ $fpath)

# Completion options
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%B%F{blue}-- %d --%f%b'
zstyle ':completion:*:warnings' format '%F{yellow}No matches for: %d%f'

# =============================================================================
#  Key Bindings
# =============================================================================

bindkey '^[[H'    beginning-of-line  # Home
bindkey '^[[F'    end-of-line        # End
bindkey '^[[3~'   delete-char        # Delete
bindkey '^[[1;5C' forward-word       # Ctrl-Right
bindkey '^[[1;5D' backward-word      # Ctrl-Left

# =============================================================================
#  Modern Tool Aliases
# =============================================================================

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# zoxide: cd replacement
if command -v z >/dev/null 2>&1; then
  alias cd='z'
fi

alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

# bat -> cat/less
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat --paging=always'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
  alias less='batcat --paging=always'
fi

# ripgrep -> grep
if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

# fd -> find
if command -v fdfind >/dev/null 2>&1; then
  alias find='fdfind'
  alias fd='fdfind'
elif command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

# btop -> top/htop
if command -v btop >/dev/null 2>&1; then
  alias top='btop'
  alias htop='btop'
fi

# helix -> nano/vi/vim
if command -v hx >/dev/null 2>&1; then
  alias nano='hx'
  alias vi='hx'
  alias vim='hx'
fi

# code-insiders -> code
if command -v code-insiders >/dev/null 2>&1; then
  alias code='code-insiders'
fi

# =============================================================================
#  Custom Functions
# =============================================================================

# Load all custom ZSH functions
for func in "$HOME/.config/zsh/functions/"*.zsh(N); do
  source "$func"
done
