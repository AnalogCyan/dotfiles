# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

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

# Initialize completion system
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

# Tool Initializations
command -v thefuck >/dev/null && eval "$(thefuck --alias 2>/dev/null)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Load fzf
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Initialize Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# iTerm2 Integration (works via SSH)
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

# VS Code Insiders shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code-insiders --locate-shell-integration-path zsh)"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Plugin Management (Manual)
ZSH_PLUGINS_DIR="$HOME/.local/share/zsh/plugins"

# FZF plugins (highest priority)
fpath+=( "$ZSH_PLUGINS_DIR/fzf-zsh-plugin" )
source "$ZSH_PLUGINS_DIR/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh"

fpath+=( "$ZSH_PLUGINS_DIR/fzf-tab" )
source "$ZSH_PLUGINS_DIR/fzf-tab/fzf-tab.plugin.zsh"

fpath+=( "$ZSH_PLUGINS_DIR/zsh-fzf-history-search" )
source "$ZSH_PLUGINS_DIR/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh"

# Fish-like plugins
fpath+=( "$ZSH_PLUGINS_DIR/zsh-history-substring-search" )
source "$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh"

fpath+=( "$ZSH_PLUGINS_DIR/zsh-autosuggestions" )
source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"

# Navigation plugins
fpath+=( "$ZSH_PLUGINS_DIR/zoxide" )
source "$ZSH_PLUGINS_DIR/zoxide/zoxide.plugin.zsh"

fpath+=( "$ZSH_PLUGINS_DIR/cd-gitroot" )
source "$ZSH_PLUGINS_DIR/cd-gitroot/cd-gitroot.plugin.zsh"

# Syntax and text editing plugins
fpath+=( "$ZSH_PLUGINS_DIR/fast-syntax-highlighting" )
source "$ZSH_PLUGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

fpath+=( "$ZSH_PLUGINS_DIR/zsh-autopair" )
source "$ZSH_PLUGINS_DIR/zsh-autopair/zsh-autopair.plugin.zsh"

# Utility plugins
fpath+=( "$ZSH_PLUGINS_DIR/zsh-you-should-use" )
source "$ZSH_PLUGINS_DIR/zsh-you-should-use/zsh-you-should-use.plugin.zsh"

fpath+=( "$ZSH_PLUGINS_DIR/zsh-eza" )
source "$ZSH_PLUGINS_DIR/zsh-eza/zsh-eza.plugin.zsh"

# Plugin configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# EZA parameters
typeset -A EZA_PARAMS
EZA_PARAMS=(
  all   '--icons --git --group-directories-first'
  long  '--icons --git'
  tree  '--tree --icons'
)

# Custom completion paths
fpath=(~/.zsh.d/ $fpath)

# Completion options
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%B%F{blue}-- %d --%f%b'
zstyle ':completion:*:warnings' format '%F{yellow}No matches for: %d%f'

# Key Bindings
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char

# Use terminfo for word navigation (modern best practice)
[[ -n "${terminfo[kLFT5]}" ]] && bindkey "${terminfo[kLFT5]}" backward-word
[[ -n "${terminfo[kRIT5]}" ]] && bindkey "${terminfo[kRIT5]}" forward-word

# Fallbacks for terminals without proper terminfo
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Modern Tool Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# zoxide: cd replacement
if command -v z >/dev/null 2>&1; then
  alias cd='z'
fi

alias mkdir='mkdir -pv'

# bat -> cat/less (Debian uses batcat)
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

# fd -> find (Debian uses fdfind)
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

# Custom Functions
for func in "$HOME/.config/zsh/functions/"*.zsh(N); do
  source "$func"
done

# Alias transparency: remind what an alias actually calls
autoload -Uz add-zsh-hook
function _alias_reminder() {
  local cmd="${1%% *}"
  local alias_val="${aliases[$cmd]}"
  [[ -n "$alias_val" ]] && print -P "%F{243}alias: $cmd → $alias_val%f"
}
add-zsh-hook preexec _alias_reminder
