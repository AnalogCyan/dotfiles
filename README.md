# dotfiles

My personal dotfiles I use in Linux and Windows.

## Linux

To install, run `./install.sh` and follow the prompts.

### functions

These are the various aliases I have set in [fish](https://fishshell.com/).

`function fish_greeting` Changed the fish greeting to display a custom welcome message with the weather on one system, and a fortune everywhere else.

`alias ..` & `alias cd..` Alternate commands for cd ...

`alias bsh` Alternate command to run bash.

`alias clera` Fix common miss-type of clear.

`alias !!` & `alias fuck` Run as root, previous command if no arguments given.

`alias generate-password` Generate a random password.

`alias lh` List hidden files in a shorter command.

`alias mkdir` Have mkdir always run with -pv.

`sudo !!` & `sudo!!` Run previous command as root.

`alias vi` Ensure vi always opens vim.



### .gitconfig

Just my personal git configuration.

## Windows

To install, run `.\install.ps1` and follow the prompts.

### functions

These are the various aliases I have set in powershell.

`alias adbIP` Connect adb over IP in one command.

`alias cd` Make cd behave as it does in Linux.

`alias compile` Compile the specified source for both Windows and Linux (currently C++ only).

`alias fish` Run commands in the fish shell.

`alias home` Map ~ to the user's home directory, like in Linux.

`alias vim` Map both vi and vim to vim in WSL.

### ahk

My current [AutoHotkey](https://www.autohotkey.com) scripts.

### profiles.json

Config for [Windows Terminal](https://devblogs.microsoft.com/commandline/introducing-windows-terminal/).

### profile.ps1

Profile config for powershell.

### .gitconfig

Just my personal git configuration.
