#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

export PATH="$HOME/bin:$PATH"

alias vi='vim'
alias cls='clear'

export PF_INFO="ascii title os host kernel uptime"

if [ "$(hostname | cut -f1 -d".")" = 'boole' ]; then
  if which fish >/dev/null; then
	clear && fish
  elif which pfetch >/dev/null; then
  	clear && pfetch
  elif which fortune >/dev/null; then
  	clear && fortune -n 50 -s
  else
  	clear
  fi
else
  fortune -n 50 -s
  #pfetch
fi