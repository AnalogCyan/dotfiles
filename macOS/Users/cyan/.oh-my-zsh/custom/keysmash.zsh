# Generates a random 'keysmash' string, prints it, copies it to clipboard.

alias keysmash="cat /dev/urandom | env LC_CTYPE=C tr -dc 'asdfghjkl;' | fold -w 20 | head -n 1 | tee /dev/tty | tr -d '\n' | pbcopy"
