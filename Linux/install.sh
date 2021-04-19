#!/usr/bin/env bash

printf 'This script will first ensure your system is up to date and ensure some software is installed.'
printf 'Would you like to continue? (y/N) : '
read -r update
if [ "$update" = "y" ] || [ "$update" = "Y" ]; then
  sudo apt update --fix-missing && sudo apt upgrade && sudo apt autoremove && sudo apt --fix-broken install
  sudo apt install gcc g++ git vim fish htop
fi

printf 'Set fish as the default shell? (y/N) : '
read -r fish

printf 'Install fish config & functions? (y/N) : '
read -r ffunc

printf 'Install bin scripts & shortcuts? (y/N) : '
read -r dbin

printf 'Install sowm & config? (y/N) : '
read -r sowm

printf 'Install git config? (y/N) : '
read -r gitconf

if [ "$fish" = "y" ] || [ "$fish" = "Y" ]; then
  chsh -s /usr/bin/fish
fi

if [ "$dbin" = "y" ] || [ "$dbin" = "Y" ]; then
echo "Copying bin scripts into ~/bin/..."
  mkdir -pv ~/bin/apps/
  cp ./home/cyan/bin/* ~/bin/
  echo "Copying bin shortcuts into ~/.local/share/applications/..."
  mkdir -pv ~/.local/share/applications/
  cp ./home/cyan/.local/share/applications/* ~/.local/share/applications/
fi

if [ "$ffunc" = "y" ] || [ "$ffunc" = "Y" ]; then
  echo "Copying fish configs into ~/.config/fish/..."
  mkdir -pv ~/.config/fish/functions/
  cp ./.config/fish/* ~/.config/fish/
fi

if [ "$sowm" = "y" ] || [ "$sowm" = "Y" ]; then
  mkdir -pv ~/sowm/
  git clone https://github.com/dylanaraps/sowm.git ~/sowm/

  mkdir -pv /usr/share/xsessions/
  cp ./usr/share/xsessions/sowm.desktop /usr/share/xsessions/

  yes | cp -rf ./home/cyan/sowm/config.h ~/sowm/
fi

if [ "$gitconf" = "y" ] || [ "$gitconf" = "Y" ]; then
  echo "Copying git config into ~/.gitconfig..."
  cp ../.gitconfig ~/.gitconfig
fi