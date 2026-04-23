# Dotfiles

Dotfiles and setup scripts for macOS and Debian (workstation).

## Repository Structure

```
dotfiles/
├── macos/
│   └── home/                          # rsync'd to ~/
│       ├── .zshrc
│       ├── .zlogin
│       ├── .zsh_plugins.txt
│       ├── .gitconfig
│       ├── .fzf.zsh
│       ├── .tmux.conf
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
│       ├── .fzf.zsh
│       ├── .tmux.conf
│       └── .config/
│           ├── starship.toml
│           ├── Code - Insiders/User/settings.json
│           └── zsh/functions/
│               └── zsh_greeting.zsh
├── install-macos.zsh
└── install-debian.sh
```

Each platform directory mirrors the filesystem layout of a live system.
Install scripts use `rsync` to deploy dotfiles onto the system in one operation.

## macOS

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install-macos.zsh
./install-macos.zsh
```

The installer handles: system updates, Homebrew setup, package/cask installation,
zsh plugin cloning, Monaspace Nerd Font, zsh configuration, dotfile deployment via
rsync, iCloud symlinks, and pfetch installed to `/usr/local/bin`.

## Debian

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install-debian.sh
./install-debian.sh
```

The installer handles: apt updates, package installation (ripgrep, fd, hx, bat,
eza, btop, fzf, zoxide, yt-dlp and more), VS Code Insiders via Microsoft apt repo,
zsh plugin cloning, ctop, Monaspace Nerd Font, dotfile deployment via rsync, pfetch
installed to `/usr/local/bin`, and zsh as default shell.

## Key Components

- **Starship** cross-platform prompt (macOS and Debian)
- **zsh plugins** cloned directly to `~/.local/share/zsh/plugins` (no plugin manager)
- **VS Code Insiders** installed on all platforms; `code` aliased to `code-insiders`
- **Editor fallback chain** resolved at shell startup: `code-insiders → code → hx → vim`; exported as `EDITOR`, `VISUAL`, `GIT_EDITOR`
- **Modern tool aliases** eza, bat, ripgrep, fd, btop, helix
- **zsh_greeting** available as a command on macOS and Debian; auto-runs on interactive login shells via `.zlogin`
- **pfetch** installed to `/usr/local/bin` on macOS and Debian
