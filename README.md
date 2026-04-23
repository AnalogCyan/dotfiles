# Dotfiles

Dotfiles and setup script for macOS and Debian (workstation). Single
cross-platform installer; shared configs with per-platform overlay where
needed.

## Repository Structure

```
dotfiles/
├── shared/
│   ├── home/                          # rsync'd to ~/ on all platforms
│   │   ├── .zshrc
│   │   ├── .zlogin
│   │   ├── .zsh_plugins.txt
│   │   ├── .gitconfig
│   │   ├── .fzf.zsh
│   │   ├── .tmux.conf
│   │   └── .config/
│   │       ├── starship.toml
│   │       └── zsh/functions/
│   │           └── zsh_greeting.zsh
│   └── vscode/
│       └── settings.json              # copied to platform-specific path
├── macos/
│   └── home/                          # macOS-only overlay, rsync'd after shared/
│       └── Library/
│           ├── Application Support/iTerm2/DynamicProfiles/vscode-synced.json
│           └── Preferences/com.googlecode.iterm2.plist
└── install.sh
```

Shared shell configs use command-existence guards (`command -v`) rather than
OS detection, so the same `.zshrc` works on both platforms without branching.
VS Code settings use platform-specific keys (`*.osx`, `*.linux`) in a single
file; VS Code reads only the relevant keys at runtime.

## Installation

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer detects the OS via `uname -s` and runs the appropriate steps.

### macOS

Handles: system updates, Homebrew setup, formula/cask installation, zsh plugin
cloning, Monaspace Nerd Font, zsh configuration, dotfile deployment via rsync
(shared + macOS overlay), VS Code settings to `~/Library/Application Support/`,
iCloud symlinks, and pfetch installed to `/usr/local/bin`.

### Debian

Handles: apt updates, package installation (ripgrep, fd, hx, bat, eza, btop,
fzf, zoxide, yt-dlp and more), VS Code Insiders via Microsoft apt repo, zsh
plugin cloning, ctop, Monaspace Nerd Font, dotfile deployment via rsync, VS Code
settings to `~/.config/`, pfetch installed to `/usr/local/bin`, and zsh as
default shell.

## Key Components

- **Starship** cross-platform prompt
- **zsh plugins** cloned directly to `~/.local/share/zsh/plugins` (no plugin manager)
- **VS Code Insiders** installed on both platforms; `code` aliased to `code-insiders`
- **Editor fallback chain** resolved at shell startup: `code-insiders → code → hx → vim`; exported as `EDITOR`, `VISUAL`, `GIT_EDITOR`
- **Modern tool aliases** eza, bat (or batcat on Debian), ripgrep, fd (or fdfind on Debian), btop, helix
- **zsh_greeting** available as a command; auto-runs on interactive login shells via `.zlogin`; shows outdated brew or apt packages depending on platform
- **pfetch** installed to `/usr/local/bin`
