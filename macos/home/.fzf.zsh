# Setup fzf
# ---------

# Set FZF_PATH if not already set
if [[ -z "$FZF_PATH" ]]; then
  if [[ -d /opt/homebrew/opt/fzf ]]; then
    FZF_PATH=/opt/homebrew/opt/fzf
  elif [[ -d /usr/local/opt/fzf ]]; then
    FZF_PATH=/usr/local/opt/fzf
  elif [[ -d ~/.fzf ]]; then
    FZF_PATH=~/.fzf
  fi
fi

if [[ -n "$FZF_PATH" && ! "$PATH" == *"${FZF_PATH}/bin"* ]]; then
  export PATH="$PATH:${FZF_PATH}/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && [[ -f "${FZF_PATH}/shell/completion.zsh" ]] && source "${FZF_PATH}/shell/completion.zsh"

# Key bindings
# ------------
[[ -f "${FZF_PATH}/shell/key-bindings.zsh" ]] && source "${FZF_PATH}/shell/key-bindings.zsh"
