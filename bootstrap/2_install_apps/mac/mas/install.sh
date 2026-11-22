#!/usr/bin/env bash
#
# install.sh - install Mac App Store apps with `mas`, one category at a time.
# A category is one Masfile in the masfile/ folder: masfile/<category>.mas (e.g. essential.mas).
#
# Usage:
#   bash install.sh              # no argument: only essential.mas
#   bash install.sh essential    # the same, written out
#   bash install.sh productivity # only productivity.mas
#   bash install.sh all          # every *.mas (a lot of apps: only when you really want all)
#
# Why separate from ../brew? The App Store apps need you to be signed in to the App Store,
# which cannot be automated. So this runs after you have signed in by hand.
#
# For every line it prints skip / installed / FAIL, like ../brew/install.sh.
# Needs `mas`: it is installed by ../brew (essential.brewfile has brew "mas").
# mas 4.0.0+ needs root to install apps, so it asks for the administrator password.
# Use `bash run.sh`: it asks once at the start and keeps the sudo credentials alive.
# Safe to re-run: what is installed is skipped.
# To add a category: create masfile/<name>.mas. This script does not change.

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../../_common/lib.sh"   # shared helpers, see ../brew/install.sh
require_mac_user

# is_installed ID: is the App Store app with this id installed?
#   `mas list` prints one line per app: "<id>  <name>  (<version>)". We compare the first column.
is_installed() {
    mas list | awk '{ print $1 }' | grep -qx "$1"
}

# install_category: go through "$CURRENT.mas" one line at a time.
install_category() {
    local file="$DIR/masfile/$CURRENT.mas"
    [ -f "$file" ] || { warn "[$CURRENT] no such Masfile: $CURRENT.mas"; return 1; }

    log "[$CURRENT] $CURRENT.mas"

    local line id name installed=0 skipped=0 failed=0

    while IFS= read -r line; do
        # Ignore blank lines and comments.
        case "$line" in
            ''|'#'*) continue ;;
        esac

        # First word = App Store id, the rest = name.
        read -r id name <<< "$line"

        if is_installed "$id"; then
            echo "    skip       $id $name"
            skipped=$((skipped + 1))
        elif mas install "$id"; then
            echo "    installed  $id $name"
            installed=$((installed + 1))
        else
            warn "[$CURRENT] FAIL: $id $name (App Store signed in? administrator password correct?)"
            failed=$((failed + 1))
        fi
    done < "$file"

    echo "    -> $installed installed, $skipped skipped, $failed failed"
}

main() {
    [ "$#" -le 1 ] || { echo "Usage: bash install.sh [CATEGORY | all]   (no argument = essential)" >&2; exit 1; }
    load_brew || { echo "brew not found: run 'bash run.sh' in ../brew first (it installs Homebrew)." >&2; exit 1; }
    command -v mas > /dev/null || { echo "mas not found: run ../brew/install.sh essential first." >&2; exit 1; }

    # No argument -> essential. Only the word "all" installs every *.mas
    # (run_categories_ext runs every category when it gets no category argument).
    local category="${1:-essential}"
    if [ "$category" = all ]; then
        run_categories_ext "$DIR/masfile" mas install_category
    else
        run_categories_ext "$DIR/masfile" mas install_category "$category"
    fi

    finish
}

main "$@"
