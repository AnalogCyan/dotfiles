#!/bin/bash

printf 'Install fish functions? (y/N) : '
read -r ffunc

printf 'Install lxterm config? (y/N) : '
read -r lxconf

printf 'Install conky configs? (y/N) : '
read -r cconf

printf 'Install git config? (y/N) : '
read -r gitconf


if [ "$ffunc" = "y" ] || [ "$ffunc" = "Y" ]; then
  echo "Copying fish functions into ~/.config/fish/functions/..."
  mkdir -pv ~/.config/fish/functions/
  cp -i ./functions/*.fish ~/.config/fish/functions/
fi

if [ "$lxconf" = "y" ] || [ "$lxconf" = "Y" ]; then
  echo "Copying lxterm config into ~/.config/lxterminal/lxterminal.conf..."
  mkdir -pv ~/.config/lxterminal/
  cp -i ./lxterminal.conf ~/.config/lxterminal/lxterminal.conf
fi

if [ "$cconf" = "y" ] || [ "$cconf" = "Y" ]; then
  echo "Copying conky configs into ~/.config/conky..."
  mkdir -pv ~/.config/conky/
  cp -i ./conky/rc.glsl ~/.config/conky/rc.glsl
  cp -i ./conky/Arco-logos.conkyrc ~/.config/conky/Arco-logos.conkyrc
fi

if [ "$gitconf" = "y" ] || [ "$gitconf" = "Y" ]; then
  echo "Copying git config into ~/.gitconfig..."
  cp -i ./.gitconfig ~/.gitconfig
fi