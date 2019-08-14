
# dotfiles
My generic dotfiles I use in Linux and Windows.

## Linux
To install, run `./install.sh` and follow the prompts.

### functions
These are the various aliases I have set in [fish](https://fishshell.com/).

`alias .. cd ..` 
`alias bsh bash` 
`alias cd.. cd ..` 
`alias clera clear` 
`alias generate-password bash -c  "< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c\${1:-32};echo;"` 
`alias lh ls -d .*` 
`alias mkdir mkdir -pv` 
`alias vi vim` 

### lxterminal.conf
Config for the terminal emulator I use, [LXTerminal](https://github.com/lxde/lxterminal).
Uses [Tomorrow Night Bright](https://github.com/ChrisKempson/Tomorrow-Theme) theme with some tweaks.

### .gitconfig
Just my personal git configuration.


## Windows
To install, run `.\install.ps1` (requires admin).

### functions
These are the various aliases I have set in powershell.

`alias adbIP` Connect adb over IP in one command. 
`alias compile` Attempt to compile the specified source for both Windows and Linux (currently C++ only).  
`alias fish` Run commands in the fish shell. 
`alias home` Map ~ to the user's home directory, like in Linux.  
`alias vim` Map both vi and vim to vim in WSL. 

### profiles.json
Config for [Windows Terminal](https://devblogs.microsoft.com/commandline/introducing-windows-terminal/).

### profile.ps1
Config

### .gitconfig
Just my personal git configuration.


## TODO

 - Add user options for what to install to the Windows installer like the Linux installer has.
 - Add some of the useful Linux aliases to Windows as well.

