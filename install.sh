#!/usr/bin/env bash

# Determine if running on compatible distro
if ! command -v apt &> /dev/null; then
  echo "Error: this script was only designed for debian-based systems. Aborting."
  return 2> /dev/null || exit
fi

# Determine if whiptail is installed.
if ! command -v whiptail &> /dev/null; then
  printf "Error: whiptail not found. Install whiptail? (Y/n) : "
  read -r wti
  if [ "$wti" = "n" ] || [ "$wti" = "N" ]; then
    echo "Error: whiptail not found. Aborting."
    return 2> /dev/null || exit
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

# add fzf
# Prompt user to install software.
whiptail --title "Install Software" --checklist --separate-output \
  "Some software will now be installed.\nYou may uncheck any you do not wish to have installed below, or select <Cancel> to skip this entirely." 20 78 10 \
  "gcc" "gcc" ON \
  "g++" "g++" ON \
  "git" "git" ON \
  "vim" "vim" ON \
  "htop" "htop" ON \
  "zsh" "zsh" ON \
  "fortune" "fortune" ON \
  "mosh" "mosh" ON \
  "screen" "screen" ON 2> results

while read choice; do
  case $choice in
    gcc)
      PACKAGES="${PACKAGES} gcc"
      ;;
    g++)
      PACKAGES="${PACKAGES} g++"
      ;;
    git)
      PACKAGES="${PACKAGES} git"
      ;;
    vim)
      PACKAGES="${PACKAGES} vim"
      ;;
    htop)
      PACKAGES="${PACKAGES} htop"
      ;;
    zsh)
      PACKAGES="${PACKAGES} zsh"
      ;;
    fortune)
      PACKAGES="${PACKAGES} fortune"
      ;;
    mosh)
      PACKAGES="${PACKAGES} mosh"
      ;;
    screen)
      PACKAGES="${PACKAGES} screen"
      ;;
    *) ;;

  esac
done < results
if ! [ -z "$PACKAGES" ]; then
  clear && echo "Installing: $PACKAGES..." && echo '' && sleep 1s
  sudo apt install $PACKAGES
fi

# Prompt user for fish specific actions if they have fish.
if [[ $PACKAGES == *"zsh"* ]] || command -v zsh &> /dev/null; then
  if (whiptail --title "Change default shell?" --yesno "Either you have chosen to install zsh, or zsh is already on your system. Would you like to change your default shell to zsh?" 8 78); then
    clear && echo "Changing shell to zsh..." && echo '' && sleep 1s
    chsh -s /usr/bin/zsh
  fi

  if (whiptail --title "Install omz?" --yesno "Install oh-my-zsh?" 8 78); then
    clear && echo "Installing oh-my-zsh..." && echo '' && sleep 1s
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  whiptail --title "Install zsh config & functions?" --checklist --separate-output \
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
    "vi" "Ensure vi always opens vim." ON \
    "yt-dlp-ba" "Run yt-dlp w/ best audio settings." ON \
    "yt-dlp-bv" "Run yt-dlp w/ best video settings." ON \
    "ytmdl-sp" "Run ytmdl w/ in a shorter command." ON 2> results

  FUNCTIONS=()
  while read choice; do
    case $choice in
      config)
        CONFIG="true"
        ;;
      fish_greeting)
        FUNCTIONS+=("fish_greeting.fish")
        ;;
      !!)
        FUNCTIONS+=("!!.fish")
        ;;
      ..)
        FUNCTIONS+=("...fish")
        ;;
      bsh)
        FUNCTIONS+=("bsh.fish")
        ;;
      cd..)
        FUNCTIONS+=("cd...fish")
        ;;
      clera)
        FUNCTIONS+=("clera.fish")
        ;;
      fuck)
        FUNCTIONS+=("fuck.fish")
        ;;
      generate-password)
        FUNCTIONS+=("generate-password.fish")
        ;;
      lh)
        FUNCTIONS+=("lh.fish")
        ;;
      mkdir)
        FUNCTIONS+=("mkdir.fish")
        ;;
      'sudo !!')
        FUNCTIONS+=("sudo !!.fish")
        ;;
      sudo!!)
        FUNCTIONS+=("sudo!!.fish")
        ;;
      vi)
        FUNCTIONS+=("vi.fish")
        ;;
      *) ;;

    esac
  done < results
  if [[ $CONFIG == *"true"* ]]; then
    clear && echo "Installing fish config..." && echo '' && sleep 1s
    mkdir -pv ~/.config/fish/
    cp -r ./Linux/home/cyan/.config/fish/config.fish ~/.config/fish/
  fi
  if ! [ -z "${FUNCTIONS[@]}" ]; then
    clear && echo "Installing functions: "${FUNCTIONS[@]}"..." && echo '' && sleep 1s
    mkdir -pv ~/.config/fish/functions/
    for i in "${FUNCTIONS[@]}"; do
      cp -r "./Linux/home/cyan/.config/fish/functions/$i" ~/.config/fish/functions/
    done
  fi
fi

# TODO: add option to specify location for fish_greeting/wthr if installed

# bin scripts/shortcuts
# TODO: add menu for selecting which to install
if (whiptail --title "~/bin" --yesno "Would you like to install bin scripts/shortcuts?" 8 78); then
  clear && echo "Installing bin scripts/shortcuts..." && echo '' && sleep 1s
  echo "Copying bin scripts into ~/bin/..."
  mkdir -pv ~/bin/apps/
  cp -r ./Linux/home/cyan/bin/* ~/bin/
  echo "Copying bin shortcuts into ~/.local/share/applications/..."
  mkdir -pv ~/.local/share/applications/
  cp -r ./Linux/home/cyan/.local/share/applications/* ~/.local/share/applications/
  echo "Installing pfetch into ~/bin/apps/pfetch/..."
  git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/
fi

# TODO: sowm & config

# git config
if command -v git &> /dev/null; then
  if (whiptail --title ".gitconfig" --yesno "Would you like to configure git?" 8 78); then
    if (whiptail --title ".gitconfig" --yesno "Do you use a DE/WM on this sytem?" 8 78); then
      clear && echo "Configuring git..." && echo '' && sleep 1s
      git config --global core.editor "code --wait -n"
      git config --global user.name "AnalogCyan"
      git config --global user.email "git@thayn.me"
    else
      clear && echo "Configuring git..." && echo '' && sleep 1s
      git config --global core.editor "vim"
      git config --global user.name "AnalogCyan"
      git config --global user.email "git@thayn.me"
    fi
  fi
fi
