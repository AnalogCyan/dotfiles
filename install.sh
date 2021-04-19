#!/usr/bin/env bash

# Determine if running on compatible distro
if ! command -v apt &> /dev/null
then
  echo "Error: this script was only designed for debian-based systems. Aborting."
  return 2>/dev/null || exit
fi

# Determine if whiptail is installed.
if command -v whiptail &> /dev/null
then
  printf "Error: this script uses whiptail for its TUI, and whiptail was not found on this system. Install whiptail? (Y/n) : "
  read -r wti
  if [ "$wti" = "n" ] || [ "$wti" = "N" ]; then
    echo "Error: whiptail not found. Aborting."
    return 2>/dev/null || exit
  else
    sudo apt install whiptail
  fi
fi

# Intro message.
whiptail --title "AnalogCyan's dotfiles" --msgbox "This script will guide you through installing my dotfiles.\nHit OK to continue." 8 78

# Prompt user to check for and install updates.
if (whiptail --title "Install Updates" --yesno "This script will first ensure the system is up to date.\nInstall updates?" 8 78); then
clear && echo "Ensuring system is up-to-date..." && echo '' && sleep 1s
  sudo apt update --fix-missing && sudo apt upgrade && sudo apt autoremove && sudo apt --fix-broken install
fi

# Prompt user to install software.
whiptail --title "Install Software" --checklist --separate-output \
"Some essential software will now be installed.\nYou may uncheck any you do not wish to have installed below, or select <Cancel> to skip this entirely." 20 78 10 \
"gcc" "Allow connections to other hosts" ON \
"g++" "Allow connections from other hosts" ON \
"git" "Allow mounting of local devices" ON \
"vim" "Allow mounting of remote devices" ON \
"fish" "The fish shell." ON 2>results

while read choice
do
	case $choice in
		gcc) PACKAGES="${PACKAGES} gcc"
		;;
		g++) PACKAGES="${PACKAGES} g++"
		;;
		git) PACKAGES="${PACKAGES} git"
		;;
    vim) PACKAGES="${PACKAGES} vim"
    ;;
    fish) PACKAGES="${PACKAGES} fish"
    ;;
		*)
		;;
	esac
done < results
if ! [ -z "$PACKAGES" ]; then
  clear && echo "Installing: $PACKAGES..." && echo '' && sleep 1s
  sudo apt install $PACKAGES
fi

# Prompt user for fish-specific actions if they have fish.
if [[ $PACKAGES == *"fish"* ]] || command -v fish &> /dev/null; then
  if (whiptail --title "Change default shell?" --yesno "Either you have chosen to install fish, or fish is already on your system. Would you like to change your default shell to fish?" 8 78); then
    clear && echo "Changing shell to fish..." && echo '' && sleep 1s
    chsh -s /usr/bin/fish
  fi

  whiptail --title "Install fish config & functions?" --checklist --separate-output \
  "Either you have chosen to install fish, or fish is already on your system. Some corresponding configs/scripts will now be installed. You may uncheck any you do not with to have installed below, or select <Cancel> to skip this entirely." 20 78 10 \
  "config" "Fish configuration." ON \
  "fish_greeting" "Custom greeting with weather or fortune." ON \
  "!!" "Run as root, previous command if no args." ON \
  ".." "Alt command for moving up a directory." ON \
  "bsh" "Alt command to run bash." ON \
  "cd.." "Alt command for moving up a directory." ON \
  "clera" "Fix common miss-type of clear." ON \
  "fuck" "Run as root, previous command if no args." ON \
  "generate-password" "Generate a random password." ON \
  "lh" "List hidden files." ON \
  "mkdir" "Have mkdir always run with -pv." ON \
  "sudo !!" "Run previous command as root." ON \
  "sudo!!" "Run previous command as root." ON \
  "vi" "Ensure vi always opens vim." ON 2>results

  while read choice
  do
  	case $choice in
  		gcc) FUNCTIONS="${FUNCTIONS} gcc"
  		;;
  		g++) FUNCTIONS="${FUNCTIONS} g++"
  		;;
  		git) FUNCTIONS="${FUNCTIONS} git"
  		;;
      vim) FUNCTIONS="${FUNCTIONS} vim"
      ;;
      fish) FUNCTIONS="${FUNCTIONS} fish"
      ;;
  		*)
  		;;
  	esac
  done < results
fi