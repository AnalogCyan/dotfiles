# Dotfiles

Dotfiles and setup script for macOS and Debian (workstation). Single
cross-platform installer; shared configs.

## Repository Structure

```
dotfiles/
├── home/                              # rsync'd to ~/ on all platforms
│   ├── .zshrc
│   ├── .zlogin
│   ├── .zsh_plugins.txt
│   ├── .gitconfig
│   ├── .fzf.zsh
│   ├── .tmux.conf
│   └── .config/
│       ├── starship.toml
│       ├── zed/
│       │   └── settings.json          # Zed editor config
│       └── zsh/functions/
│           └── zsh_greeting.zsh
└── install.sh
```

Shared shell configs use command-existence guards (`command -v`) rather than
OS detection, so the same `.zshrc` works on both platforms without branching.

## Installation

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer detects the OS via `uname -s` and runs the appropriate steps.

### macOS

Handles: system updates, Homebrew setup, formula/cask installation, zsh plugin
cloning, Monaspace Nerd Font, zsh configuration, dotfile deployment via rsync, iCloud symlinks, and pfetch installed to `/usr/local/bin`.

### Debian

Handles: apt updates, package installation (ripgrep, fd, hx, bat, eza, btop,
fzf, zoxide, yt-dlp and more), Zed, zsh plugin cloning, ctop, Monaspace Nerd
Font, dotfile deployment via rsync, pfetch installed to `/usr/local/bin`, and
zsh as default shell.

## Key Components

- **Starship** cross-platform prompt
- **zsh plugins** cloned directly to `~/.local/share/zsh/plugins` (no plugin manager)
- **Zed** installed on both platforms
- **Editor fallback chain** resolved at shell startup: `zed-insiders → zed → hx → vim`; exported as `EDITOR`, `VISUAL`, `GIT_EDITOR`
- **Modern tool aliases** eza, bat (or batcat on Debian), ripgrep, fd (or fdfind on Debian), btop, helix
- **zsh_greeting** available as a command; auto-runs on interactive login shells via `.zlogin`; shows outdated brew or apt packages depending on platform
- **pfetch** installed to `/usr/local/bin`
