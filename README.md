# ⚙ Dotfiles

These are the base dotfiles that I start with when I set up a new environment. They are stored in this repository for convenience and are broken down into macOS, Linux, and Windows sections for easy access and installation.

## 🔧 Repository Structure

```
dotfiles/
├── install.ps1       # Windows installation script
├── install.sh        # Linux installation script
├── install.zsh       # macOS installation script
├── Nix/              # Shared Unix configurations
│   └── Users/
│       └── cyan/
│           ├── bin/  # Custom scripts and utilities
│           └── ...
└── Windows/          # Windows-specific configurations
    ├── Terminal/
    ├── winget/
    └── ...
```

## 🍎 macOS

This repository contains a straightforward installation script (`install.zsh`) for setting up a new macOS environment according to my preferred configurations.

### Features

- **Package Managers**: Installs and configures Homebrew with various formulae, casks, and fonts. Also configures npm for JavaScript packages.
- **Applications**: Installs essential applications via Homebrew casks and Mac App Store (using `mas`).
- **Configuration Files**: Replaces the current `.zshrc` file with my custom configuration.
- **Shell Environment**: Installs Oh-My-Zsh with custom plugins:
  - zsh-history-substring-search
  - zsh-completions
  - zsh-you-should-use
  - zsh-syntax-highlighting
  - zsh-autosuggestions
  - fzf shell extensions
- **Binary Scripts**: Installs various custom utilities and tools to `~/bin/`.
- **iCloud Integration**: Creates symbolic links to iCloud Drive folders.
- **Git Configuration**: Sets up git with personalized configurations.

### Installation

```bash
$ git clone https://github.com/username/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
$ chmod +x install.zsh
$ ./install.zsh
```

After installation completes, you'll be prompted to restart your terminal to see the changes.

## 🐧 Linux & Homelab Server

This repository includes an installation script (`install.sh`) for setting up a new Linux environment on Debian-based distributions, with optional homelab server configurations.

### Features

- **System Compatibility**: Ensures the script runs only on compatible Debian-based systems.
- **System Updates**: Updates system packages and fixes any broken installations.
- **Software Installation**: Installs essential packages:
  - Development tools (gcc, g++, git)
  - System utilities (vim, htop, screen)
  - Shell enhancements (zsh, fortune, mosh)
  - Media tools (ffmpeg, mpv, yt-dlp)
  - Additional utilities (bat, fzf, thefuck, etc.)
- **Shell Environment**: Changes default shell to zsh and installs Oh-My-Zsh with plugins.
- **Configuration Files**: Installs custom zsh configurations and functions.
- **Server-Specific Features**: When set up as a server, additionally installs:
  - iTerm2 shell integration
  - NextDNS
  - Plex Media Server
  - Docker with proper configuration
- **Binary Scripts**: Installs pfetch and other custom utilities to `~/bin/`.
- **Git Configuration**: Sets up git with personalized settings.

### Installation

```bash
$ git clone https://github.com/username/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
$ chmod +x install.sh
$ ./install.sh
```

During installation, you'll be asked if you're setting up a server environment. Based on your response, additional configurations will be applied.

## 🪟 Windows

The Windows installation script (`install.ps1`) provides comprehensive setup for Windows 10 and 11 environments.

### Features

- **System Configuration**: Configures Windows features including WSL2, Hyper-V, and Windows Sandbox.
- **System Updates**: Ensures Windows is up-to-date using PowerShell modules.
- **Package Managers**: Installs and configures:
  - Chocolatey
  - Windows Package Manager (winget)
- **Applications**: Installs a wide range of applications using both package managers:
  - Development tools (Git, Visual Studio, VSCode, etc.)
  - System utilities (PowerToys, Terminal, etc.)
  - Media applications (Plex, Spotify, etc.)
  - Gaming platforms (Steam, Epic Games, etc.)
- **PowerShell Environment**: Installs and configures:
  - Oh-My-Posh
  - PSReadLine
  - Terminal-Icons
- **Configuration Files**: Installs custom configurations for:
  - PowerShell profile
  - Windows Terminal
  - Winget settings
- **Development Environments**: Sets up Flutter SDK.
- **Git Configuration**: Configures git with personalized settings.

### Installation

```powershell
# Clone the repository
git clone https://github.com/username/dotfiles.git ~\dotfiles
cd ~\dotfiles

# Run the installation script (requires non-admin PowerShell)
.\install.ps1
```

After installation completes, you'll be prompted to restart your computer to apply all changes.

## ⚠️ Important Notes

- Always review the scripts before running them to ensure they match your needs.
- Replace the git configuration with your own information.
- Some applications may require additional manual setup after installation.
- These scripts are designed for personal use and may need adjustment for your specific environment.

## 🔄 Updates and Maintenance

These dotfiles are regularly updated as my workflow evolves. To update your existing installation:

```bash
# Navigate to your dotfiles directory
cd ~/dotfiles

# Pull the latest changes
git pull

# Run the appropriate installation script for your OS
# macOS:
./install.zsh
# Linux:
./install.sh
# Windows:
./install.ps1
```
