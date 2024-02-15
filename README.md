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

## 🐧 Linux

This repository contains a straightforward installation script for setting up a new Linux environment according to my preferred configurations. Files are located in the `Linux` directory.

This script includes the following operations:

**System Compatibility Check**: It checks if the system is a Debian-based distribution since the script was designed for these types of systems. If the check fails, the script will abort.

**System Updates**: This part ensures that the system packages are updated, removed when not needed, and that all installations are fixed if broken.

**Software Installation**: It installs essential packages like `gcc`, `g++`, `git`, `vim`, `htop`, `zsh`, `fortune`, `mosh`, `screen`.

**Default Shell Change**: It switches the default shell to zsh.

**Oh-My-Zsh Installation**: It installs `oh-my-zsh`.

**Zsh Configuration and Functions**: Post oh-my-zsh installation, the script replaces the `.zshrc` file with my custom configuration and copies custom function files to `~/.oh-my-zsh/custom/functions/`.

**Bin Scripts and Shortcuts**: It copies bin scripts and `.desktop` shortcuts from the repository to `~/bin` and `~/.local/share/applications/` respectively. It also installs `pfetch`.

**Git Configurations**: If git has been installed, the script sets up git with my user configurations: name, email, and preferred editor.

To set up a new Linux environment with these configurations, clone the repository and run the setup script like so:

```bash
$ git clone https://github.com/username/dotfiles.git ~/dotfiles
$ cd ~/dotfiles/
$ chmod +x install.sh
$ ./install.sh
```

After the script finishes executing, restart your terminal to see the full changes. You may need to log out and back in if the default shell was changed during the configuration process.

Remember to replace the `.gitconfig` with your own info, and bear in mind you may need to adjust the files and scripts as needed to match your setup. This README section is specific for the given script and doesn't take into account other potential files or changes.

## 🪟 Windows

As of now, my Windows-related dotfiles are outdated as the Windows platform is no longer my primary desktop operating system. However, I understand the importance of providing up-to-date configurations for those who still find it useful.

Please bear with me as I am currently in the process of updating my Windows dotfiles. Once completed, a comprehensive, updated guide similar to the macOS and Linux sections will be provided here. Thank you for your patience and understanding!

Stay tuned for more updates!

## 🖥️ Homelab Server

This repository includes a `server.sh` script designed to orchestrate the configuration of my personal homelab server environment.

To initially configure the server, the script executes the [Linux install script](#-linux) to set up a base environment that suits my preferences. This involves installations of various packages and tools, configuration of dotfiles, and more. Please refer to the [Linux section](#-linux) for more details.

After the Linux environment setup, the script proceeds with several server-specific steps:

**Check System Compatibility**: Verifies if the server is a Debian-based system since the script is specifically designed to cater to such systems. If the system fails this compatibility check, the script halts immediately.

**Software Installation**: Installs selected server-specific applications and tools, crucial to my homelab server setup, which are not covered in the Linux install script.

**Homelab Specific Configurations**: Implements homelab specific configurations such as specific `~/bin` scripts/apps setup, NextDNS, Plex, and Docker installations, among other customizations.

Here's how you can set up a new homelab server environment using these configurations:

```bash
$ git clone https://github.com/username/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
$ chmod +x server_setup.sh
$ ./server_setup.sh
```

On completion, the script will prompt a server reboot to ensure all changes come into effect.

Remember to replace the `.gitconfig` with your own info, and bear in mind you may need to adjust the files and scripts as needed to match your setup. This README section is specific for the given script and doesn't take into account other potential files or changes.
