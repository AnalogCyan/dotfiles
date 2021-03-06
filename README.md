# ⚙ dotfiles

My personal dotfiles/scripts I use in Linux and Windows.

⚠ I'm currently reworking the installers, and some parts are broken. Also some of these files are now outdated. I wouldn't rely on this as an accurate or working representation of my dotfiles until it's updated and this message is removed.

## 🐧 Linux

To install, run `./install.sh` in bash and follow the prompts.

### misc

`~/sowm/config.h` is my configuration for [sowm](https://github.com/dylanaraps/sowm), my current desktop of choice.

`/etc/systemd/system/lock.service` is a simple system service for running my lock script on suspend.

My current fish config, `~/.config/fish/config.fish`, simply adds `~/bin` to `$PATH`.

### functions

These are the various aliases I have set in [fish](https://fishshell.com/).

`fish_greeting` Custom greeting to display pfetch, weather, and fortune.

`..` & `cd..` Alternate commands for moving up a directory.

`bsh` Alternate command to run bash.

`clera` Fix common miss-type of clear.

`!!` & `fuck` Run as root, previous command if no arguments given.

`generate-password` Generate a random password.

`lh` List hidden files in a shorter command.

`mkdir` Have mkdir always run with -pv.

`sudo !!` & `sudo!!` Run previous command as root.

`vi` Ensure vi always opens vim.

### bin

These are various scripts I've added to my user bin directory. Some depend on certain apps being installed in weird ways, due to the nature of one system I use.

Some of these also have .desktop files to facilitate easy launching from GUI launchers.

`col` Script for extracting columns from a file.

`files` Launch [fff](https://github.com/dylanaraps/fff) in [st](https://st.suckless.org/).

`fish` Launch fish from `~/bin/apps/`.

`lock` Lock the system using [betterlockscreen](https://github.com/pavanjadhaw/betterlockscreen).

`lolpipes` Launch [pipes.sh](https://github.com/pipeseroni/pipes.sh) with [lolcat](https://github.com/busyloop/lolcat) in [st](https://st.suckless.org/).

`neofetch` Launch neofetch from `~/bin/apps/`.

`pfetch` Launch pfetch from `~/bin/apps`, ensuring custom config is set.

`pipes` Launch [pipes.sh](https://github.com/pipeseroni/pipes.sh) in [st](https://st.suckless.org/).

`Traverse` Script for searching directories.

`wall` Set a random wallpaper & lock screen using [feh](https://feh.finalrewind.org/) and [betterlockscreen](https://github.com/pavanjadhaw/betterlockscreen).

`weather` Fetch the current weather for `$CITY` via [wttr.in](https://github.com/chubin/wttr.in).

## 🐱‍💻 Windows

To install, run `.\install.ps1` in pwsh and follow the prompts.

### functions

These are the various aliases I have set in powershell.

`adbIP` Connect adb over IP in one command.

`cd` Make cd behave as it does in Linux.

`compile` Compile the specified source for both Windows and Linux (currently C++ only).

`fish` Run commands in the fish shell.

`home` Map ~ to the user's home directory, like in Linux.

`vim` Map both vi and vim to vim in Win or WSL, depending on what is installed.

### ahk

My current [AutoHotkey](https://www.autohotkey.com) scripts.

### profiles.json

Config for [Windows Terminal](https://github.com/Microsoft/Terminal).

### profile.ps1

Profile config for PowerShell.
