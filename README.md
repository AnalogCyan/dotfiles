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
│   ├── .ssh/
│   │   ├── config                     # shared; machine hosts go in ~/.ssh/config.local
│   │   └── keys/*.pub                 # public keys the 1Password agent serves
│   └── .config/
│       ├── 1Password/ssh/agent.toml   # key order for the 1Password SSH agent
│       ├── ghostty/config.ghostty
│       ├── git/ignore                 # global gitignore
│       ├── starship.toml
│       ├── zed/
│       │   └── settings.json          # Zed editor config, synced from live by hand
│       └── zsh/functions/
│           └── zmx.zsh
└── install.sh
```

Shared shell configs use command-existence guards (`command -v`) rather than
OS detection, so the same `.zshrc` works on both platforms without branching.

`home/.ssh/config` is shared the same way: it pins one public key per host and
finds the 1Password agent socket wherever the OS keeps it. Hosts that exist on
one machine only belong in `~/.ssh/config.local`, which the shared file
includes and the installer never touches.

## Installation

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer detects the OS via `uname -s` and walks you through it: pick
which steps to run, pick optional packages (macOS), review the plan (press `d`
to see a diff of dotfiles it would overwrite), then watch each step run with
its live output. It asks for your password once, up front.

```bash
./install.sh --dry-run   # show what each step would change, touch nothing
./install.sh --yes       # no prompts: every step, no optional packages
```

It runs on the stock macOS bash 3.2. Logs go to `~/.local/state/dotfiles/`,
and dotfiles it overwrites are backed up to `~/.dotfiles-backup/` first. Set
`GITHUB_TOKEN` to lift GitHub's API rate limit if a download step hits it.

### macOS

Handles: system updates, Homebrew setup, formula/cask installation (plus an
optional set you pick from), zsh plugin cloning, Monaspace Nerd Font, zsh
configuration, dotfile deployment via rsync, iCloud symlinks, and the Ghostty
config symlink.

### Debian

Handles: apt updates, package installation (ripgrep, fd, hx, bat, eza, btop,
fzf, zoxide, yt-dlp and more), Ghostty, Zed, zsh plugin cloning, ctop, zmx,
croc, yazi, Monaspace Nerd Font, dotfile deployment via rsync, pfetch installed
to `/usr/local/bin`, and zsh as default shell.

## Key Components

- **Starship** cross-platform prompt
- **zsh plugins** cloned directly to `~/.local/share/zsh/plugins` (no plugin manager)
- **Zed** installed on both platforms
- **Editor fallback chain** resolved at shell startup: `zed-insiders → zed → hx → vim`; exported as `EDITOR`, `VISUAL`, `GIT_EDITOR`
- **Modern tool aliases** eza, bat (or batcat on Debian), ripgrep, fd (or fdfind on Debian), btop, helix
- **Agent shells** (Claude Code, Codex, Cursor, Copilot and others, detected by
  environment variable) get the same PATH and environment but skip the
  interactive layer: no prompt, plugins, history, or aliases that replace
  standard commands, and pagers set to `cat`. Aliases that only add commands
  (`lg`, `brewup`) still work. Scripts never see aliases either way.
  `DOTFILES_AGENT=0` or `1` overrides detection.
- **Login greeting** in `.zlogin`: pfetch plus a cached count of outdated brew or apt packages
- **pfetch-rs** from Homebrew on macOS, installed to `/usr/local/bin` on Debian
