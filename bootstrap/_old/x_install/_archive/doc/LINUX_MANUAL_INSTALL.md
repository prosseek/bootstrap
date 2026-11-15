# Linux Manual Installation Guide

## Automatic Installation (Recommended)

Most packages are now **automatically installed** using alternative methods when apt is not available:

- **yazi**: Automatically installed via snap
- **glow**: Automatically installed via snap  
- **mdcat**: Automatically installed via cargo (if Rust is installed)
- **marp-cli**: Automatically installed via npm (if Node.js is installed)
- **mermaid-cli**: Automatically installed via npm (if Node.js is installed)
- **tree-sitter**: Automatically installed via cargo (if Rust is installed)

The installation script will:
1. Check if the package is available in apt
2. If not, automatically try alternative methods (snap, cargo, npm)
3. Provide helpful instructions if the alternative tool is not installed

## Prerequisites for Auto-Installation

For best results, install these tools first:

### Snap (usually pre-installed on Ubuntu)
```bash
sudo apt install snapd
```

### Rust/Cargo (for Rust-based tools)
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### Node.js/npm (for npm-based tools)
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

## Manual Installation (If Needed)

### Using snap

```bash
# Yazi - Terminal file manager
snap install yazi

# Glow - Markdown viewer
snap install glow
```

### Using cargo (Rust)

First, install Rust if you haven't:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

Then install packages:
```bash
# Mdcat - Markdown viewer
cargo install mdcat

# Yazi - Alternative installation
cargo install yazi-fm

# Tree-sitter - Alternative installation
cargo install tree-sitter-cli
```

### Using npm (Node.js)

First, install Node.js if you haven't:
```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

Then install packages:
```bash
# Marp CLI - Markdown presentation
npm install -g @marp-team/marp-cli

# Mermaid CLI - Diagram generation
npm install -g @mermaid-js/mermaid-cli

# Tree-sitter - Alternative installation
npm install -g tree-sitter-cli
```

### WezTerm

WezTerm requires manual installation from their official repository:

```bash
# Download and install the latest release
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update
sudo apt install wezterm
```

Or download AppImage from: https://wezfurlong.org/wezterm/installation.html

### Briss (PDF Cropper)

Briss is a Java GUI application that requires manual installation:

```bash
# Download from GitHub releases
wget https://github.com/mbaeuerle/Briss-2.0/releases/download/release-0.9/Briss-0.9.jar

# Run with Java
java -jar Briss-0.9.jar
```

## Package Alternatives

If you prefer apt-only installation, here are some alternatives:

| Original Package | apt Alternative | Notes |
|-----------------|-----------------|-------|
| yazi | ranger, nnn, lf | Terminal file managers |
| glow | pandoc, less | Markdown viewers |
| mdcat | pandoc | Markdown processor |
| marp-cli | reveal.js | Presentation tools |
| wezterm | alacritty, kitty | Terminal emulators |

## Verification

After installation, verify packages are installed:

```bash
# Check installed commands
which yazi glow mdcat marp mermaid tree-sitter wezterm

# Test versions
yazi --version
glow --version
mdcat --version
marp --version
```

## Recommended Installation Order

1. **Essential tools first** (available via apt):
   ```bash
   sudo apt install -y tmux neovim vim fzf fd-find ripgrep bat zoxide eza entr mc
   ```

2. **Development tools** (if you plan to use cargo/npm):
   ```bash
   # Install Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   
   # Install Node.js
   curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

3. **Optional enhanced tools** (based on your needs):
   ```bash
   # Via snap
   snap install yazi glow
   
   # Via cargo
   cargo install mdcat yazi-fm
   
   # Via npm
   npm install -g @marp-team/marp-cli @mermaid-js/mermaid-cli
   ```

## Notes

- **snap**: Available by default on Ubuntu 16.04+
- **cargo**: Requires ~1GB disk space for Rust toolchain
- **npm**: Requires Node.js (can be large with dependencies)
- Some packages may have different feature sets across installation methods
