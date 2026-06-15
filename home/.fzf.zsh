# Setup fzf
# ---------

# Resolve the actual fzf installation root separately from the plugin's config path.
if [[ -z "${DOTFILES_FZF_ROOT:-}" ]]; then
  if [[ -d /opt/homebrew/opt/fzf ]]; then
    DOTFILES_FZF_ROOT=/opt/homebrew/opt/fzf
  elif [[ -d /usr/local/opt/fzf ]]; then
    DOTFILES_FZF_ROOT=/usr/local/opt/fzf
  elif [[ -d /usr/share/doc/fzf ]]; then
    # Debian/Ubuntu fzf package location
    DOTFILES_FZF_ROOT=/usr/share/doc/fzf
  elif [[ -d ~/.fzf ]]; then
    DOTFILES_FZF_ROOT=~/.fzf
  fi
fi

if [[ -n "${DOTFILES_FZF_ROOT:-}" && ! "$PATH" == *"${DOTFILES_FZF_ROOT}/bin"* && -d "${DOTFILES_FZF_ROOT}/bin" ]]; then
  export PATH="$PATH:${DOTFILES_FZF_ROOT}/bin"
fi

# Auto-completion
# ---------------
if [[ $- == *i* ]]; then
  [[ -f "${DOTFILES_FZF_ROOT}/shell/completion.zsh" ]] && source "${DOTFILES_FZF_ROOT}/shell/completion.zsh"
  [[ -f "${DOTFILES_FZF_ROOT}/examples/completion.zsh" ]] && source "${DOTFILES_FZF_ROOT}/examples/completion.zsh"
fi

# Key bindings
# ------------
[[ -f "${DOTFILES_FZF_ROOT}/shell/key-bindings.zsh" ]] && source "${DOTFILES_FZF_ROOT}/shell/key-bindings.zsh"
[[ -f "${DOTFILES_FZF_ROOT}/examples/key-bindings.zsh" ]] && source "${DOTFILES_FZF_ROOT}/examples/key-bindings.zsh"

# Expose the real install root after config selection so later plugin logic can
# still find package-managed assets without treating that path as the config dir.
[[ -n "${DOTFILES_FZF_ROOT:-}" ]] && export FZF_PATH="${DOTFILES_FZF_ROOT}"
