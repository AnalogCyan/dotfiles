
# dotfiles
My generic dotfiles I use in Linux and Windows.

## Linux
To install, run `./install.sh` and follow the prompts.

### functions
These are the various aliases I have set in [fish](https://fishshell.com/).

`function fish_greeting` Change the fish greeting to display neofetch.

`alias ..` & `alias cd..` Alternate command for cd ...

`alias bsh` Alternate command to run bash.

`alias clera` Fix common miss-type of clear.

`alias !!` & `alias fuck` Run as root, previous command if no arg.

`alias generate-password` Generate a random password.

`alias lh` List hidden files in a shorter command.

`alias mkdir` Have mkdir always run with -pv.

`alias neoclear` Single command for clearing the screen and showing neofetch.

`sudo !!` & `sudo!!` Run previous command as root.

`alias vi` Ensure vi always opens vim.

### lxterminal.conf
Config for the terminal emulator I use, [LXTerminal](https://github.com/lxde/lxterminal).
Uses [Tomorrow Night Bright](https://github.com/ChrisKempson/Tomorrow-Theme) theme with some tweaks.

### conky
My current [conky](https://github.com/brndnmtthws/conky) configs.

### .gitconfig
Just my personal git configuration.


## Windows
To install, run `.\install.ps1` (requires admin).

### functions
These are the various aliases I have set in powershell.

`alias adbIP` Connect adb over IP in one command. 

`alias cd` Make cd behave as it does in Linux.

`alias compile` Compile the specified source for both Windows and Linux (currently C++ only).  

`alias fish` Run commands in the fish shell. 

`alias home` Map ~ to the user's home directory, like in Linux.  

`alias vim` Map both vi and vim to vim in WSL. 

### profiles.json
Config for [Windows Terminal](https://devblogs.microsoft.com/commandline/introducing-windows-terminal/).

### profile.ps1
Profile config for powershell.

### .gitconfig
Just my personal git configuration.


## TODO

✔ Add user options for what to install to the Windows installer like the Linux installer has.
- Add some of the useful Linux aliases to Windows as well.
