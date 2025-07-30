### btop wrapper & aliases for macOS only ###
if command -v btop >/dev/null 2>&1; then

  # Wrap the real btop binary so Zsh can autoload this file
  btop() {
    command btop "$@"
  }

  # Override the classics
  alias top='btop'
  alias htop='btop'

fi
