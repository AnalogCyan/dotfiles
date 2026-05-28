# XDG Base Directory
: ${XDG_CONFIG_HOME:=${HOME}/.config}
: ${XDG_DATA_HOME:=${HOME}/.local/share}
: ${XDG_CACHE_HOME:=${HOME}/.cache}
: ${XDG_STATE_HOME:=${HOME}/.local/state}

# PATH
path=(
  ${HOME}/.usagi/bin
  ${HOME}/.npm-global/bin
  ${HOME}/.local/bin
  ${HOME}/bin
  /usr/local/bin
  $path
)
typeset -U path fpath

mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Ghostty terminfo: bootstrap on SSH remotes, fall back to xterm-256color
if [[ "$TERM" == "xterm-ghostty" ]]; then
  if ! infocmp "$TERM" &>/dev/null; then
    local ghostty_ti
    for ghostty_ti (
      "/Applications/Ghostty.app/Contents/Resources/terminfo/78/xterm-ghostty"
      "/Applications/Ghostty.app/Contents/Resources/terminfo/x/xterm-ghostty"
      "/usr/share/terminfo/x/xterm-ghostty"
      "/lib/terminfo/x/xterm-ghostty"
      "/etc/terminfo/x/xterm-ghostty"
    ) {
      if [[ -f "$ghostty_ti" ]]; then
        mkdir -p "$HOME/.terminfo/x"
        cp "$ghostty_ti" "$HOME/.terminfo/x/xterm-ghostty"
        export TERMINFO="$HOME/.terminfo"
        export TERMINFO_DIRS="$HOME/.terminfo:${TERMINFO_DIRS:-/etc/terminfo:/lib/terminfo:/usr/share/terminfo}"
        break
      fi
    }
  fi
  if ! infocmp "$TERM" &>/dev/null; then
    export TERM="xterm-256color"
  fi
fi

# Editor
if (( $+commands[zed-insiders] )); then
  export EDITOR='zed-insiders --wait -n'
elif (( $+commands[zed] )); then
  export EDITOR='zed --wait -n'
elif (( $+commands[hx] )); then
  export EDITOR='hx'
else
  export EDITOR='vim'
fi
export VISUAL="${EDITOR}" GIT_EDITOR="${EDITOR}"
export PAGER='less' LESS='-R --use-color -M'

# Completion paths
fpath=(~/.zsh.d/ $fpath)

ZSH_PLUGINS_DIR="$HOME/.local/share/zsh/plugins"

# Plugins: parse manifest to build fpath and populate plugin_files (must precede compinit)
local p_file="${HOME}/.zsh_plugins.txt"
local -a plugin_files=()

if [[ -f "$p_file" ]]; then
  local line name
  while read -r line; do
    # Remove trailing comments and whitespace
    line="${line%%#*}"
    line="${line#${line%%[![:space:]]*}}"
    line="${line%${line##*[![:space:]]}}"
    [[ -z "$line" ]] && continue

    if [[ "$line" == http* ]]; then
      local temp="${line#*://}"
      local domain="${temp%%/*}"
      local path_part="${temp#*/}"
      local domain_clean="${domain%.*}"
      local domain_hyphen="${domain_clean//./-}"
      local path_hyphen="${path_part//\//-}"
      if [[ "$path_part" != "$temp" ]]; then
        name="${domain_hyphen}-${path_hyphen}"
      else
        name="${domain_hyphen}"
      fi
      name="${name%.git}"
    else
      name="${line##*/}"
    fi

    local target="$ZSH_PLUGINS_DIR/$name"
    if [[ -d "$target" ]]; then
      fpath+=("$target")
      local plugin_file
      for plugin_file ("$target/$name.plugin.zsh" "$target/$name.zsh" "$target/$name.sh" "$target"/*.plugin.zsh(N)) {
        if [[ -f "$plugin_file" ]]; then
          [[ "$name" != "zoxide" ]] && plugin_files+=("$plugin_file")
          break
        fi
      }
    fi
  done < "$p_file"
fi

# Completion system
autoload -Uz compinit
local zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
mkdir -p "$XDG_CACHE_HOME/zsh"

if [[ ! -f "$zcompdump" ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
mkdir -p "$XDG_CACHE_HOME/zsh/zcompcache"

# History
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory histignorealldups histignorespace sharehistory incappendhistory extendedhistory nobeep

mkdir -p "$XDG_STATE_HOME/zsh"
CORRECT_IGNORE_FILE='.*'
setopt globdots
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# fzf: always source our config first (sets DOTFILES_FZF_ROOT, PATH, completions, key-bindings)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Tools

(( $+commands[starship] )) && eval "$(starship init zsh)"

if (( $+commands[zmx] )); then
  eval "$(zmx completions zsh)"
fi

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Plugins: source (after compinit)
local f
for f ("$plugin_files[@]") { [[ -f "$f" ]] && source "$f" }

# zoxide: init default (creates 'z'), then alias cd->z below
if [[ -f "$ZSH_PLUGINS_DIR/zoxide/zoxide.plugin.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zoxide/zoxide.plugin.zsh"
elif (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
(( $+functions[z] )) && alias cd='z'

export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window 'down:5:hidden:wrap'
  --bind 'ctrl-/:toggle-preview'
"

# Plugin config
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%B%F{blue}-- %d --%f%b'
zstyle ':completion:*:warnings' format '%F{yellow}No matches for: %d%f'

# Key bindings
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char

(( $+terminfo[kLFT5] )) && bindkey "${terminfo[kLFT5]}" backward-word
(( $+terminfo[kRIT5] )) && bindkey "${terminfo[kRIT5]}" forward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'

(( $+commands[bat] )) && alias cat='bat --paging=never' less='bat --paging=always'
(( $+commands[batcat] )) && alias cat='batcat --paging=never' less='batcat --paging=always'
(( $+commands[rg] )) && alias grep='rg'
if (( $+commands[fdfind] )); then
  alias find='fdfind' fd='fdfind'
elif (( $+commands[fd] )); then
  alias find='fd'
fi
(( $+commands[btop] )) && alias top='btop' htop='btop'
(( $+commands[lazygit] )) && alias lg='lazygit'
(( $+commands[hx] )) && alias nano='hx' vi='hx' vim='hx'
(( $+commands[zmx] )) && alias tmux='zmx' screen='zmx'
(( $+commands[brew] )) && alias brewup='brew update && brew upgrade --greedy && mo clean && mo optimize && zsh'
(( $+commands[apt] )) && alias aptup='sudo apt update && sudo apt full-upgrade'

# Custom functions
for f ("$HOME/.config/zsh/functions/"*.zsh(N)) source "$f"

# Alias transparency
autoload -Uz add-zsh-hook
function _alias_reminder() {
  local cmd="${1%% *}"
  local alias_val="${aliases[$cmd]}"
  [[ -n "$alias_val" ]] && print -P "%F{243}alias: $cmd → $alias_val%f"
}
add-zsh-hook preexec _alias_reminder
