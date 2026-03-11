# Dotfiles

Dotfiles and setup scripts for macOS, Debian (workstation), and Windows.

## Repository Structure

```
dotfiles/
├── macos/
│   └── home/                          # rsync'd to ~/
│       ├── .zshrc
│       ├── .zlogin
│       ├── .zsh_plugins.txt
│       ├── .gitconfig
│       └── .config/
│           ├── starship.toml
│           ├── Code - Insiders/User/settings.json
│           └── zsh/functions/
│               └── zsh_greeting.zsh
├── debian/
│   └── home/                          # rsync'd to ~/
│       ├── .zshrc
│       ├── .zlogin
│       ├── .zsh_plugins.txt
│       ├── .gitconfig
│       └── .config/
│           ├── starship.toml
│           ├── Code - Insiders/User/settings.json
│           └── zsh/functions/
│               └── zsh_greeting.zsh
├── windows/
│   ├── home/                          # copied to %USERPROFILE%
│   │   ├── .gitconfig
│   │   ├── .config/starship.toml
│   │   └── Documents/PowerShell/
│   │       └── Microsoft.PowerShell_profile.ps1
│   └── appdata/                       # deployed to %LOCALAPPDATA%
│       ├── Packages/.../settings.json # Windows Terminal
│       └── Microsoft/WinGet/Settings/ # WinGet settings
├── install-macos.zsh
├── install-debian.sh
└── install-windows.ps1
```

Each platform directory mirrors the filesystem layout of a live system.
Install scripts use `rsync` (macOS/Linux) or `Copy-Item` (Windows) to deploy
dotfiles onto the system in one operation.

## macOS

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install-macos.zsh
./install-macos.zsh
```

The installer handles: system updates, Homebrew setup, package/cask
installation, VS Code Insiders, zsh configuration, dotfile deployment via rsync,
iCloud symlinks, and pfetch installed to `/usr/local/bin`.

## Debian

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install-debian.sh
./install-debian.sh
```

The installer handles: apt updates, package installation (ripgrep, fd, hx, bat,
eza, btop, fzf, zoxide, yt-dlp and more), VS Code Insiders via Microsoft apt
repo, Antidote (zsh plugin manager), ctop, dotfile deployment via rsync, pfetch
installed to `/usr/local/bin`, and zsh as default shell.

## Windows

```powershell
git clone https://github.com/AnalogCyan/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install-windows.ps1
```

If running from Windows PowerShell 5.x the script will install winget and pwsh,
then relaunch itself in pwsh automatically.

The installer handles: winget app installation, PowerShell modules, sudo
configuration, Windows features, disabling AI features (Copilot, Recall, Bing
search, telemetry), and dotfile deployment.

## Key Components

- **Starship** cross-platform prompt (all platforms)
- **Antidote** zsh plugin manager (macOS/Linux)
- **VS Code Insiders** installed on all platforms; `code` aliased to `code-insiders`
- **Editor fallback chain** resolved at shell startup: `code-insiders → code → hx → vim`; exported as `EDITOR`, `VISUAL`, `GIT_EDITOR`
- **Modern tool aliases** eza, bat, ripgrep, fd, btop, helix
- **zsh_greeting** available as a command on all platforms; auto-runs on interactive login shells (macOS and Linux via `.zlogin`)
- **pfetch** installed to `/usr/local/bin` on macOS and Linux
