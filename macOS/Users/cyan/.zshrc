# Environment Paths
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin:$PATH

# Oh-my-zsh Path
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="arrow"

# Update Settings
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Configurations
DISABLE_MAGIC_FUNCTIONS="true"
COMPLETION_WAITING_DOTS="true"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243,underline"
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# Plugins
plugins=(
  1password
  copypath
  copyfile
  copybuffer
  docker
  docker-compose
  emoji
  extract
  genpass
  gh
  git
  gitignore
  history
  isodate
  lol
  macos
  mosh
  npm
  pip
  safe-paste
  screen
  vscode
  you-should-use
  zsh-syntax-highlighting  # MUST be loaded before zsh-history-substring-search to work.
  fast-syntax-highlighting # MUST be loaded before zsh-history-substring-search to work.
  zsh-autocomplete         # MUST be loaded before zsh-history-substring-search to work.
  zsh-autosuggestions
  zsh-interactive-cd
  zsh-history-substring-search # Must be loaded after zsh-syntax-highlighting to work.
)

# Load Oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Load Functions
eval $(thefuck --alias)
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Session Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Test iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Custom Defintions
zsh_greeting

# Commented Settings
# HYPHEN_INSENSITIVE="true"
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true"
# ZSH_CUSTOM=/path/to/new-custom-folder
# export MANPATH="/usr/local/man:$MANPATH"
# export LANG=en_US.UTF-8
# export ARCHFLAGS="-arch x86_64"
