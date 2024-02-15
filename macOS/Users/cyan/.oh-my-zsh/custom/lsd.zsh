# This function runs the most feature-rich 'ls'-like command available, and pipes the output to 'lolcat' to colorize it

function lsd() {
  if command -v logo-ls &>/dev/null; then
    logo-ls "$@" | lolcat
  elif command -v exa &>/dev/null; then
    exa "$@" | lolcat
  elif command -v ls &>/dev/null; then
    ls "$@" | lolcat
  else
    echo "ls command not found"
  fi
}
