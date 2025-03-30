# ⚙ Dotfiles

These are the base dotfiles that I start with when I set up a new environment. They are stored in this repository for convenience and are broken down into macOS, Linux, and Windows sections for easy access and installation.

## 🔧 Repository Structure

```
dotfiles/
├── install.ps1       # Windows installation script
├── install.sh        # Linux installation script
├── install.zsh       # macOS installation script
├── install-min.zsh   # Minimal macOS installation script
├── starship.toml     # Cross-platform Starship prompt configuration
├── Nix/              # Shared Unix configurations
│   ├── .zshrc        # ZSH configuration file
│   ├── .zsh_plugins.txt # Antidote plugin definitions
│   ├── bin/          # Custom scripts and utilities
│   │   ├── pfetch    # System information display script
│   │   └── weather   # Weather display script
│   ├── functions/    # ZSH function definitions
│   ├── miniNAS/      # Docker compose setup for NAS
│   │   ├── compose.yml
│   │   └── preseed.cfg
│   └── Valkyrie/     # Docker compose setup for Valkyrie
│       ├── compose.yml
│       └── preseed.cfg
└── Windows/          # Windows-specific configurations
    ├── Microsoft.PowerShell_profile.ps1   # PowerShell profile
    ├── Terminal/     # Windows Terminal settings
    ├── winget/       # Windows Package Manager settings
    └── ...
```

## 🍎 macOS

The macOS installation script (`install.zsh`) provides a comprehensive setup for macOS environments with modern development tools and shell configurations.

### Features

- **System Updates**: Ensures system is up-to-date before installation
- **Package Managers**:
  - Homebrew with various formulae, casks, and fonts (auto-installs if missing)
  - npm for JavaScript packages
- **Applications**:
  - Essential applications via Homebrew casks
  - Mac App Store applications via `mas`
  - Direct downloads for apps not available through package managers
- **Shell Environment**:
  - Uses Antidote for plugin management
  - Installs essential ZSH plugins:
    - zsh-history-substring-search
    - fast-syntax-highlighting
    - zsh-autosuggestions
    - zsh-autocomplete
    - zsh-z
    - zsh-you-should-use
    - fzf extensions
  - Starship prompt for a modern terminal experience
- **Development Tools**:
  - Git with personalized configurations
  - Modern command-line tools (bat, fzf, logo-ls, etc.)
  - Development essentials (gcc, cmake, python, etc.)
- **System Integration**:
  - iCloud Drive symbolic links
  - Custom binary scripts in ~/bin
  - Automated backup of existing configurations

### Installation

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.zsh
./install.zsh
```

## 🐧 Linux & Homelab Server

The Linux installation script (`install.sh`) is designed for Debian-based systems with special considerations for server environments.

### Features

- **System Compatibility**:
  - Debian-based systems only
  - Optional server-specific configurations
- **Package Management**:
  - APT package installation with error handling
  - NPM packages for development
  - Modern CLI tools (logo-ls, bat, fzf, etc.)
- **Shell Environment**:
  - ZSH as default shell
  - Antidote for plugin management
  - Starship prompt configuration
  - Custom ZSH functions and configurations
- **Development Tools**:
  - Git configuration
  - 1Password CLI integration
  - Development essentials (gcc, g++, make, etc.)
- **Server Features** (when enabled):
  - Docker with proper configuration
  - Plex Media Server
  - NextDNS integration
  - iTerm2 shell integration
  - Docker Compose configurations for:
    - miniNAS setup
    - Valkyrie server
- **Security & Monitoring**:
  - System monitoring tools (htop, btop)
  - SSH configuration
  - Secure shell access (mosh)

### Installation

```bash
git clone https://github.com/AnalogCyan/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## 🪟 Windows

The Windows installation script (`install.ps1`) provides a modern development environment setup for Windows 11.

### Features

- **System Requirements**:
  - Windows 11 compatibility check
  - Non-admin installation with elevated commands when needed
  - Sudo functionality (native or gsudo fallback)
- **Package Management**:
  - Winget (Windows Package Manager) with automatic installation
  - PowerShell module management
- **Applications**:
  - Development tools (Git, VSCode, Python, etc.)
  - System utilities (PowerToys, Terminal, NanaZip)
  - Productivity apps and browsers
  - Security tools (1Password)
- **Shell Environment**:
  - PowerShell profile configuration
  - Modern PowerShell modules:
    - PSReadLine
    - Terminal-Icons
    - PSFzf
    - posh-git
  - Starship prompt integration
- **Development Environment**:
  - Git configuration
  - SSH setup
  - Development essentials
  - Nerd Fonts installation
- **System Configuration**:
  - Windows Optional Features management
  - System PATH updates
  - Windows Terminal settings

### Installation

```powershell
# Clone the repository
git clone https://github.com/AnalogCyan/dotfiles.git ~\dotfiles
cd ~\dotfiles

# Run the installation script (requires non-admin PowerShell)
.\install.ps1
```

## 🌟 Key Components

### Starship Prompt

The repository uses [Starship](https://starship.rs/), consistently configured across all platforms:

- Minimal and performant design
- Git integration with status indicators
- Directory path with smart truncation
- Custom prompt symbol with status coloring
- Platform-specific optimizations
- Extensible configuration in starship.toml

### Antidote Plugin Manager

[Antidote](https://getantidote.github.io/) provides modern plugin management for Unix systems:

- Fast plugin loading
- Simple plugin definition format
- Compatible with popular ZSH plugins
- Automatic plugin updates
- Cross-platform compatibility

## ⚠️ Important Notes

- All scripts include comprehensive error handling and status reporting
- Backups are automatically created for existing configurations
- Windows installation requires Windows 11 or newer
- Server installations include additional tools and configurations
- Some features may require manual intervention or confirmation
