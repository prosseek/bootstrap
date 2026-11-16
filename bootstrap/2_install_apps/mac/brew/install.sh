#!/usr/bin/env bash
#
# install.sh - install apps with Homebrew, one category at a time.
# A category is one Brewfile in the brewfile/ folder: brewfile/<category>.brewfile (e.g. essential.brewfile).
#
# Usage:
#   bash install.sh essential    # only essential.brewfile
#   bash install.sh              # no argument: every *.brewfile
#
# For every line of a Brewfile it prints what happened:
#   skip       already installed by brew, nothing done
#   exists     a cask whose app is already in /Applications (installed by hand): not touched
#   installed  was missing, installed now
#   FAIL       was missing, could not be installed
# Each category then gets OK (no FAIL) or FAIL, and a summary table is printed at the end.
#
# Needs Homebrew: run 1_first_step/mac/2_run.sh first.
# Safe to re-run: what is installed is skipped.
# To add a category: create brewfile/<name>.brewfile. This script does not change.
# App Store apps are not here: see ../mas.

# `set -u`: an unset variable is an error (catches typos).
# No `set -e`: one failed app must not stop the others; failures are reported at the end.
set -u

# DIR = the absolute path of the folder this script lives in, wherever it is run from.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared helpers: require_mac_user, load_brew, log, warn, run_categories, finish ...
source "$DIR/../../../_common/lib.sh"
require_mac_user

# cask_app_exists LINE: for a line like  cask "obsidian",  is its app already in /Applications?
# `brew bundle check` only knows what brew installed itself. An app you installed by hand
# looks "not installed" to brew, and `brew install --cask` then stops with
#   "It seems there is already an App at /Applications/Obsidian.app".
# So before installing a cask we ask brew which .app the cask contains
# (brew info --cask --json=v2 ... -> artifacts -> "app") and look for it on disk.
# APP_DIR can be changed for testing; python3 is only used to read that JSON.
cask_app_exists() {
    local line="$1" token app
    case "$line" in 'cask '*) ;; *) return 1 ;; esac
    # cask "obsidian", args: ...  ->  obsidian
    token="$(printf '%s' "$line" | sed -E 's/^cask[[:space:]]+"([^"]+)".*/\1/')"
    app="$(brew info --cask --json=v2 "$token" 2>/dev/null | python3 -c '
import json, sys
try:
    for a in json.load(sys.stdin)["casks"][0]["artifacts"]:
        if "app" in a:
            print(a["app"][0]); break
except Exception:
    pass
')"
    [ -n "$app" ] && [ -e "${APP_DIR:-/Applications}/$app" ]
}

# install_category: go through "$CURRENT.brewfile" one line at a time.
# (run_categories sets CURRENT and calls this once per category.)
#
# Why one line at a time? `brew bundle` on the whole file skips what is installed but does
# not tell us clearly which line was skipped and which was installed. So each line is put
# alone into a temporary Brewfile and handed to brew twice:
#   brew bundle check --file=ONE_LINE   exit 0 = this item is already installed -> skip
#   brew bundle       --file=ONE_LINE   install it
# brew itself decides what "installed" means for brew / cask / tap / vscode lines.
# The lines are processed in file order, so a `tap` line comes before the items that need it.
install_category() {
    local file="$DIR/brewfile/$CURRENT.brewfile"
    [ -f "$file" ] || { warn "[$CURRENT] no such Brewfile: $CURRENT.brewfile"; return 1; }

    log "[$CURRENT] $CURRENT.brewfile"

    local one line installed=0 skipped=0 existing=0 failed=0
    one="$(mktemp)"

    # IFS= and -r keep each line exactly as written (no trimming, no backslash handling).
    while IFS= read -r line; do
        # Ignore blank lines and comments.
        case "$line" in
            ''|'#'*) continue ;;
        esac

        printf '%s\n' "$line" > "$one"

        if brew bundle check --file="$one" > /dev/null 2>&1; then
            echo "    skip       $line"
            skipped=$((skipped + 1))
        elif cask_app_exists "$line"; then
            echo "    exists     $line   (app already in /Applications, not installed by brew)"
            existing=$((existing + 1))
        elif brew bundle --file="$one"; then
            echo "    installed  $line"
            installed=$((installed + 1))
        else
            # warn makes run_step report this category as FAIL.
            warn "[$CURRENT] FAIL: $line"
            failed=$((failed + 1))
        fi
    done < "$file"

    rm -f "$one"
    echo "    -> $installed installed, $skipped skipped, $existing exist already, $failed failed"
}

main() {
    [ "$#" -le 1 ] || { echo "Usage: bash install.sh [CATEGORY]" >&2; exit 1; }
    load_brew || { echo "brew not found: run 1_first_step/mac/2_run.sh first." >&2; exit 1; }

    # One category given: just that one. None given: every brewfile/*.brewfile.
    run_categories_ext "$DIR/brewfile" brewfile install_category "$@"

    finish
}

main "$@"
