# ⚙ Dotfiles

These are the base dotfiles that I start with when I set up a new environment. They are stored in this repository for convenience and are broken down into macOS, Linux, and Windows sections for easy access and installation.

## 🍎 macOS

This repository contains a straightforward installation script for setting up a new macOS environment according to my preferred configurations. Files are located in the `macOS` directory.

This script covers several areas:

**Applications**: It installs essential apps like Homebrew, and other tools in `~/bin/apps`.

**Configuration Files**: It replaces the current `.zshrc` file with my custom configuration, and includes extra setups for `oh-my-zsh`.

**Package Managers**: It leverages Homebrew to install various packages, casks, and fonts. Furthermore, it makes use of npm for JavaScript package installations.

**MAS Apps**: This script also handles the installation of various Mac App Store apps using their respective MAS ids.

**Oh-My-Zsh**: Lastly, Oh-My-Zsh and its plugins are installed. The script ensures that source files for plugins are added to the `.zshrc` file for proper usage.

To get started, clone the repository and run the provided script like so:

```bash
$ git clone https://github.com/username/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
$ chmod +x install.zsh
$ ./install.zsh
```

That's it! Your new macOS environment should now be set up with my dotfiles. Restart the terminal to see the changes.

Remember to replace the `.gitconfig` with your own info, and bear in mind you may need to adjust the files and scripts as needed to match your setup. This README section is specific for the given script and doesn't take into account other potential files or changes.

## 🐧 Linux & Homelab Server

This repository contains a straightforward installation script for setting up a new Linux environment according to my preferred configurations. Files are located in the `Linux` directory. It also includes setup steps specific for homelab server environments, which can be optionally executed.

This script includes the following operations:

**System Compatibility Check**: It checks if the system is a Debian-based distribution since the script was designed for these types of systems. If the check fails, the script will abort.

**System Updates**: This part ensures that the system packages are updated, removed when not needed, and that all installations are fixed if broken.

**Software Installation**: It installs essential packages like `gcc`, `g++`, `git`, `vim`, `htop`, `zsh`, `fortune`, `mosh`, `screen`.

**Default Shell Change**: It switches the default shell to zsh.

**Oh-My-Zsh Installation**: It installs `oh-my-zsh`.

**Zsh Configuration and Functions**: Post oh-my-zsh installation, the script replaces the `.zshrc` file with my custom configuration and copies custom function files to `~/.oh-my-zsh/custom/functions/`.

**Server Specific Operations**: For users setting up a homelab server, the script can optionally execute server-specific steps like installing selected applications and tools, implementing homelab specific configurations, among other customizations.

**Bin Scripts and Shortcuts**: It copies bin scripts and shortcuts from the repository to `~/bin`. It also installs `pfetch`.

**Git Configurations**: If git has been installed, the script sets up git with my user configurations: name, email, and preferred editor.

To set up a new Linux environment or a homelab server environment with these configurations, clone the repository and run the setup script like so:

```bash
$ git clone https://github.com/username /dotfiles.git ~/dotfiles
$ cd ~/dotfiles/
$ chmod +x install.sh
$ ./install.sh
```

During the execution of the script, it will ask if you are setting up a server environment and proceed with the additional server-specific configurations if affirmed.

After the script finishes executing, you will be prompted to restart your system to see the full changes.

Remember to replace the `.gitconfig` with your own info, and bear in mind you may need to adjust the files and scripts as needed to match your setup. This README section is specific for the given script and doesn't take into account other potential files or changes.

## 🪟 Windows

As of now, my Windows-related dotfiles are outdated as the Windows platform is no longer my primary desktop operating system. However, I understand the importance of providing up-to-date configurations for those who still find it useful.

Please bear with me as I am currently in the process of updating my Windows dotfiles. Once completed, a comprehensive, updated guide similar to the macOS and Linux sections will be provided here. Thank you for your patience and understanding!

Stay tuned for more updates!

```

```
