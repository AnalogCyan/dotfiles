# Setup fzf
# ---------

# Set FZF_PATH if not already set
if [[ -z "$FZF_PATH" ]]; then
  if [[ -d /usr/share/doc/fzf ]]; then
    # Debian/Ubuntu fzf package location
    FZF_PATH=/usr/share/doc/fzf
  elif [[ -d ~/.fzf ]]; then
    FZF_PATH=~/.fzf
  fi
fi

if [[ -n "$FZF_PATH" && ! "$PATH" == *"${FZF_PATH}/bin"* && -d "${FZF_PATH}/bin" ]]; then
  export PATH="$PATH:${FZF_PATH}/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && [[ -f "${FZF_PATH}/examples/completion.zsh" ]] && source "${FZF_PATH}/examples/completion.zsh"

# Key bindings
# ------------
[[ -f "${FZF_PATH}/examples/key-bindings.zsh" ]] && source "${FZF_PATH}/examples/key-bindings.zsh"
