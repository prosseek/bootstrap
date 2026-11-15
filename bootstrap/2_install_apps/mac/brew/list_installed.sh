#!/usr/bin/env bash
#
# list_installed.sh - write what Homebrew has installed on THIS Mac to installed/installed.<computer>.txt
# (e.g. installed/installed.m4.txt), so every Mac keeps its own list in the installed/ folder.
#
# Usage:
#   bash list_installed.sh            # <computer> = this Mac's name (LocalHostName, as set by 1_hostname.sh)
#   bash list_installed.sh m4         # use the name "m4" instead
#
# It uses `brew bundle dump`, which writes the installed taps, formulae and casks
# as Brewfile lines, each with its one-line description above it (new Homebrew does this by
# default; the old --describe switch is disabled):
#
#   # Command-line fuzzy finder written in Go
#   brew "fzf"
#   # Terminal emulator
#   cask "iterm2"
#
# Only what you installed yourself is listed for formulae (not the libraries brew pulled in
# as dependencies). App Store apps are not here: see ../mas/list_installed.sh.
#
# installed/installed.<computer>.txt is only a report, overwritten when the same Mac runs again.
# To choose the apps you want on a new Mac, copy lines (with their # comment) into
# brewfile/Brewfile.<group>, then:
#   bash install.sh <group>
# It is not a Brewfile.<group>, so install.sh never reads it.

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../../_common/lib.sh"   # shared helpers (log, warn, load_brew, computer_name ...)
require_mac_user

main() {
    [ "$#" -le 1 ] || { echo "Usage: bash list_installed.sh [COMPUTER_NAME]" >&2; exit 1; }
    load_brew || { echo "brew not found: run 1_first_step/mac/2_run.sh first." >&2; exit 1; }

    local name out tmp
    name="$(computer_name "${1:-}")"
    mkdir -p "$DIR/installed"
    out="$DIR/installed/installed.$name.txt"
    tmp="$(mktemp)"

    log "Reading installed Homebrew items (brew bundle dump)"
    # --force: overwrite $tmp (mktemp already created it). --tap/--formula/--cask: only these
    # three kinds (no App Store apps, no VSCode extensions).
    if ! brew bundle dump --force --tap --formula --cask --file="$tmp"; then
        rm -f "$tmp"
        warn "brew bundle dump failed"
        finish
        return
    fi

    {
        echo "# installed.$name.txt -- Homebrew items on $name. Made by list_installed.sh."
        echo "# Copy the lines you want (with their # comment) into brewfile/Brewfile.<group>, then:  bash install.sh <group>"
        echo
        cat "$tmp"
    } > "$out"
    rm -f "$tmp"

    cat "$out"
    echo
    log "$(grep -c -E '^(tap|brew|cask) ' "$out") items -> $out"
}

main "$@"
