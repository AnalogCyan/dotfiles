# ⚙ Dotfiles

Base dotfiles and setup scripts for macOS, Debian (workstation), and Windows. This README reflects the current state of the repository and the features actually implemented by the scripts.

## 🔧 Repository Structure

```
dotfiles/
├── macOS.zsh          # macOS installation script
├── Debian.sh          # Debian (Trixie-tuned) installation script
├── Windows.ps1        # Windows installation script
├── starship.toml      # Cross-platform Starship prompt configuration
├── Code/
│   └── settings.json  # VS Code user settings (macOS-oriented)
├── Nix/               # Shared Unix bits
│   ├── bin/           # Custom scripts (copied to ~/bin)
│   │   ├── pfetch
│   │   └── weather
│   └── functions/     # ZSH functions (copied to ~/.config/zsh/functions)
│       ├── bat.zsh
│       ├── btop.zsh
│       ├── cd.zsh
│       ├── rm.zsh
│       └── zsh_greeting.zsh
└── Windows/
    ├── Microsoft.PowerShell_profile.ps1   # PowerShell profile
    ├── Terminal/settings.json             # Windows Terminal settings
    └── winget/settings.json               # Winget settings
```

## 🍎 macOS

The macOS installer is `macOS.zsh`.

### What it does

- System updates via `softwareupdate`
- Installs Homebrew if missing and updates it if present
- Installs Homebrew formulae: antidote, bat, btop, fortune, fzf, lazygit, starship, thefuck, xz, yt-dlp, zoxide, zsh, eza
- Installs Homebrew casks: 1password, 1password-cli, tailscale-app, chatgpt, FiraCode/Hack Nerd Fonts, setapp, balenaetcher, crystalfetch, iina, mactracker, modrinth, raspberry-pi-imager, transmission, utm, xcodes-app, xiv-on-mac, visual-studio-code, iterm2, messenger
- Sets Homebrew `zsh` as the default shell
- Installs `~/bin` tools and clones `pfetch`
- Copies ZSH functions to `~/.config/zsh/functions`
- Creates a minimal `~/.zshrc` if none is provided in the repo
- Creates iCloud and Downloads symlinks (`~/iCloud`, `~/Downloads`)
- Copies `starship.toml` to `~/.config/starship.toml`
- Configures Git (name/email/editor)

### Install

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x macOS.zsh
./macOS.zsh
```

Note: The script references optional files like `Nix/.zshrc` and `Nix/.zsh_plugins.txt`. If they are absent (as in this repo), a sensible minimal `~/.zshrc` is generated.

## 🐧 Linux (Debian)

The Linux installer is `Debian.sh` and targets Debian (tuned for Trixie), but should work on derivatives with minor adjustments.

### What it does

- Apt system update/upgrade and cleanup
- Installs core packages: bat, btop, fortune-mod, fzf, lazygit, starship, thefuck, xz-utils, yt-dlp, zoxide, zsh, eza, git, curl, ca-certificates
- Installs Antidote (ZSH plugin manager) from git
- Installs `~/bin` tools and clones `pfetch`
- Copies ZSH functions to `~/.config/zsh/functions`
- Copies `starship.toml` to `~/.config/starship.toml`
- Creates a minimal `~/.zshrc` when needed
- Sets `zsh` as the default shell
- Configures Git (name/email/editor)

No server-specific stacks (Docker, Plex, NextDNS, etc.) are installed by this script currently.

### Install

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x Debian.sh
./Debian.sh
```

## 🪟 Windows

The Windows installer is `Windows.ps1` and is intended for Windows 11.

### What it does

- Verifies Windows 11 and enforces running as non-admin
- Configures sudo support: uses built-in sudo if available, otherwise installs `gsudo`
- Enables/disables optional features (enables: VirtualMachinePlatform, HypervisorPlatform; disables: WindowsMediaPlayer, PowerShell v2)
- Installs apps via Winget (PowerShell, Windows Terminal, Git, Vim, VS Code, Python, Sysinternals, Starship, fzf, zoxide, PowerToys, NanaZip, OneDrive, yt-dlp, Edge, Arc, Craft, 1Password, Discord)
- Installs PowerShell modules (PSReadLine, Terminal-Icons, PSFzf, posh-git, PowerShellForGitHub, PSWindowsUpdate, BurntToast)
- Sets system PATH additions (e.g., Vim)
- Copies `starship.toml` to `%USERPROFILE%\.config\starship.toml`
- Installs PowerShell profile and Windows Terminal/Winget settings
- Configures Git (name/email/editor)
- Prepares `.ssh` directory (key generation is a TODO)

### Install

Run from a non-admin PowerShell:

```powershell
git clone https://github.com/AnalogCyan/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
./Windows.ps1
```

The script can open Microsoft Store to install Winget if it isn't present and may request elevation when enabling Windows features.

## 🌟 Key Components

### Starship Prompt

Used across all platforms with a minimal, performant configuration (`starship.toml`).

### Antidote (ZSH) on Unix

Antidote is used for plugin management on macOS/Debian when available. If repo-level `Nix/.zshrc` or `Nix/.zsh_plugins.txt` are missing, the installers create a minimal `~/.zshrc` that initializes Antidote and common tools.

### VS Code settings

Opinionated defaults live in `Code/settings.json`. Apply them manually or sync as you prefer.

## ⚠️ Notes

- Scripts include basic error handling and status output
- Existing `~/.zshrc` is backed up to `~/.zshrc.dotbak` on Unix
- Windows install requires Windows 11 or newer and should be run as non-admin; it elevates only when needed
- Some steps may require confirmation or user interaction (e.g., installing Winget from the Store)
