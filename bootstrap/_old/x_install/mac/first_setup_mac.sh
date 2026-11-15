#!/bin/bash
#
# first_setup_mac.sh - set up a fresh Mac.
#
#   1. Install Homebrew, if missing
#   2. zsh: skipped here -- see note below (already set up earlier)
#   3. Install everything listed in Brewfile via `brew bundle`
#      (taps, brew formulae, casks, mas App Store apps, vscode
#      extensions, npm/uv packages -- whatever `brew bundle dump`
#      picked up on the machine that generated it)
#
# Brewfile is the single source of truth. There is no separate
# packages_cli.txt / packages_gui.txt / packages_mas.txt anymore --
# see readme.txt for why this replaced that approach. To add or
# remove something, edit the Brewfile directly, or regenerate it from
# a Mac that already has everything installed:
#
#   brew bundle dump --file="$(dirname "$0")/Brewfile" --force

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"

# ------------------------------------------------------------
# 1. Homebrew
# ------------------------------------------------------------
if ! command -v brew &>/dev/null; then
    echo "→ Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in this script's session (Apple Silicon vs Intel)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ------------------------------------------------------------
# 2. zsh
# ------------------------------------------------------------
# Commented out: by the time this script runs, conf/zsh/run.sh has
# already been run separately (as part of the earlier bootstrap step),
# so zsh/dotfiles/oh-my-zsh/chsh are already set up. Uncomment if this
# script is ever run on a machine where that step was skipped.
# echo "→ Installing zsh..."
# source "$HOME/github/prosseek/setup/_lib/pkg/pkg.sh"
# install_pkg zsh   # conf/zsh/run.sh handles dotfiles, oh-my-zsh, and chsh

# ------------------------------------------------------------
# 3. Brewfile
# ------------------------------------------------------------
if [[ ! -f "$BREWFILE" ]]; then
    echo "❌ No Brewfile found at: $BREWFILE"
    echo ""
    echo "   Generate one on a Mac that already has everything you want"
    echo "   installed (brew formulae, casks, mas App Store apps, ...),"
    echo "   then copy it here (or commit it to the repo):"
    echo ""
    echo "     brew bundle dump --file=\"$BREWFILE\""
    echo ""
    exit 1
fi

mkdir -p "$HOME/temp"
REPORT_FILE="$HOME/temp/mac_setup_report_$(date +%Y%m%d_%H%M%S).txt"

echo "→ Running: brew bundle --file=\"$BREWFILE\""
# --verbose makes brew bundle print each entry as it's checked, so
# already-installed items show up too (not just new installs) -- that
# output is what ends up in REPORT_FILE, so a plain "nothing to do"
# run still leaves a record of what's covered.
brew bundle install --file="$BREWFILE" --verbose 2>&1 | tee -a "$REPORT_FILE"
STATUS=${PIPESTATUS[0]}

echo "" | tee -a "$REPORT_FILE"
echo "→ Full install report saved to: $REPORT_FILE"

if [[ $STATUS -eq 0 ]]; then
    echo "✅ Mac setup complete!"
else
    echo "⚠️  brew bundle exited with status $STATUS -- see $REPORT_FILE"
fi

exit $STATUS
