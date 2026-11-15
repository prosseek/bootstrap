#!/bin/bash
#
# If invoked as `sh first_setup_ubuntu.sh`, restart with Bash before
# Bash-specific features (arrays, [[ ]], PIPESTATUS) are parsed.
# (Ubuntu's default /bin/sh is dash, which does not support arrays)
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi
#
# first_setup_ubuntu.sh - set up a fresh Ubuntu/Debian/Raspberry Pi machine.
#
#   1. apt update
#   2. zsh: skipped here -- see note below (already set up earlier)
#   3. Install CLI packages listed in packages_cli.txt
#
# Edit packages_cli.txt to add or remove packages -- this script itself
# should never need to change for that.
#
# NOT handled by this script (need snap/cargo/npm/a third-party apt repo,
# which varies too much across Ubuntu/Debian/Raspberry Pi versions to
# script safely here -- install these manually if you need them):
#   yazi, eza, mdcat, tree-sitter   -- cargo, or a distro-specific apt repo
#   marp-cli, mermaid-cli, prettier, svgo -- npm
#   espanso, neovide                -- no reliable apt package

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOME/github/prosseek/setup/_lib/pkg/pkg.sh"

# ------------------------------------------------------------
# 1. apt update
# ------------------------------------------------------------
echo "→ Updating apt package list..."
sudo apt update

# ------------------------------------------------------------
# 2. zsh
# ------------------------------------------------------------
# Commented out: by the time this script runs, conf/zsh/run.sh has
# already been run separately (as part of the earlier bootstrap step),
# so zsh/dotfiles/oh-my-zsh/chsh are already set up. Uncomment if this
# script is ever run on a machine where that step was skipped.
# echo "→ Installing zsh..."
# install_pkg zsh   # conf/zsh/run.sh handles dotfiles, oh-my-zsh, and chsh

# ------------------------------------------------------------
# 3. CLI packages
# ------------------------------------------------------------
# Every install attempt is logged to REPORT_FILE as it happens, and a
# pass/fail summary is appended at the end -- same pattern as
# mac/first_setup_mac.sh used before it switched to brew bundle (see
# mac/readme.txt). Unlike the Mac version, there is no "skip if already
# installed" pre-check here: install_pkg is always called (apt itself
# is a fast no-op if a package is already installed), specifically so
# that install_pkg's conf/<name>/run.sh step keeps running on every
# invocation, exactly as before.
#
# packages_cli.txt lines can list more than one apt package name, e.g.:
#   fd fd-find
# The first name is the canonical name (used for conf/<name>/run.sh
# lookup, no matter which candidate actually gets installed). Each
# candidate is tried with "apt install" in order; if one fails, the
# next one is tried, until one succeeds or all of them have failed.
mkdir -p "$HOME/temp"
REPORT_FILE="$HOME/temp/ubuntu_setup_report_$(date +%Y%m%d_%H%M%S).txt"
INSTALLED_OK=()
INSTALLED_FAIL=()

# Install one packages_cli.txt entry, trying each candidate apt name in
# order until one succeeds.
#   $1    = canonical name (also used for conf/<name>/run.sh)
#   $2... = candidate apt package name(s) to try, in order (usually
#           just one, same as $1, unless the apt name differs)
install_apt_entry() {
    local names=("$@")
    local canonical="${names[0]}"
    local candidate status

    for candidate in "${names[@]}"; do
        if [[ "$candidate" == "$canonical" ]]; then
            echo "→ Installing: $canonical" | tee -a "$REPORT_FILE"
        else
            echo "→ Retrying with fallback apt name: $canonical -> $candidate" | tee -a "$REPORT_FILE"
        fi

        install_pkg "$canonical" "$candidate" 2>&1 | tee -a "$REPORT_FILE"
        status=${PIPESTATUS[0]}

        if [[ $status -eq 0 ]]; then
            INSTALLED_OK+=("$canonical ($candidate)")
            return
        fi
        echo "✗ Failed: $canonical ($candidate) (exit $status)" | tee -a "$REPORT_FILE"
    done

    INSTALLED_FAIL+=("$canonical (tried: ${names[*]})")
}

install_from_list() {
    local file="$1"
    while IFS= read -r line; do
        line="${line%%#*}"                       # strip comments
        line="$(echo "$line" | xargs)"            # trim whitespace
        [[ -z "$line" ]] && continue
        install_apt_entry $line                   # unquoted: splits "name [apt-name ...]"
    done < "$file"
}

echo "→ Installing CLI packages..."
install_from_list "$SCRIPT_DIR/packages_cli.txt"

# ------------------------------------------------------------
# 4. Ubuntu-specific post-setup (symlinks for renamed binaries)
# ------------------------------------------------------------
# Some Ubuntu/Debian apt packages rename upstream binaries due to
# historical package name clashes (e.g. fd-find -> fdfind, bat -> batcat).
# Create symlinks in ~/.local/bin so standard command names work out of the box.
echo "→ Configuring Ubuntu compatibility symlinks in ~/.local/bin..."
mkdir -p "$HOME/.local/bin"

if command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  ✓ Linked fdfind -> $HOME/.local/bin/fd"
fi

if command -v batcat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "  ✓ Linked batcat -> $HOME/.local/bin/bat"
fi

# ------------------------------------------------------------
# Report: what actually got installed on this machine
# ------------------------------------------------------------
{
    echo ""
    echo "=================================================="
    echo "install report - $(date)"
    echo "=================================================="
    echo ""
    echo "installed successfully (${#INSTALLED_OK[@]}):"
    for pkg in "${INSTALLED_OK[@]}"; do echo "  - $pkg"; done
    echo ""
    echo "failed (${#INSTALLED_FAIL[@]}):"
    for pkg in "${INSTALLED_FAIL[@]}"; do echo "  - $pkg"; done
} | tee -a "$REPORT_FILE"

echo ""
echo "→ Full install report saved to: $REPORT_FILE"
if [[ ${#INSTALLED_FAIL[@]} -gt 0 ]]; then
    echo "⚠️  ${#INSTALLED_FAIL[@]} package(s) failed to install -- see $REPORT_FILE"
fi

echo "✅ Ubuntu setup complete!"
