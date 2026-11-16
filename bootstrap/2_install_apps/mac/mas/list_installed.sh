#!/usr/bin/env bash
#
# list_installed.sh - read the App Store apps installed on THIS Mac and write them to
# installed/installed.<computer>.txt (e.g. installed/installed.m5.txt), grouped by App Store category.
# The computer name is in the file name, so several Macs can each keep their own list here.
#
# Usage:
#   bash list_installed.sh            # <computer> = this Mac's name (LocalHostName, as set by 1_hostname.sh)
#   bash list_installed.sh m5         # use the name "m5" instead
#
# What it does, step by step:
#   1. `mas list` gives one line per app: "<id>  <name>  (<version>)".
#   2. For each id, Spotlight (mdfind) finds the app on disk, and mdls reads the category
#      the App Store stored in the app (kMDItemAppStoreCategory). No category found -> "Unknown".
#   3. The result is sorted by category and written to installed/installed.<computer>.txt next to this script.
#
# installed/installed.<computer>.txt is only a report, it is overwritten when the same Mac runs again.
# To choose the apps you want on a new Mac, copy lines from it into masfile/<group>.mas (same
# "<id>  <name>" format), then
#   bash install.sh <group>
# It is not a Masfile, so install.sh never reads it.

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../../_common/lib.sh"   # shared helpers (log, warn, require_mac_user ...)
require_mac_user

# app_category ID: print the App Store category of the installed app with this id.
app_category() {
    local path category
    # Every App Store app carries its App Store id (kMDItemAppStoreAdamID) in the Spotlight index.
    path="$(mdfind "kMDItemAppStoreAdamID == $1" 2>/dev/null | head -n 1)"
    if [ -z "$path" ]; then echo "Unknown"; return; fi
    category="$(mdls -raw -name kMDItemAppStoreCategory "$path" 2>/dev/null)"
    case "$category" in
        ''|'(null)') echo "Unknown" ;;
        *)           echo "$category" ;;
    esac
}

main() {
    [ "$#" -le 1 ] || { echo "Usage: bash list_installed.sh [COMPUTER_NAME]" >&2; exit 1; }
    local OUT
    mkdir -p "$DIR/installed"
    OUT="$DIR/installed/installed.$(computer_name "${1:-}").txt"

    command -v mas > /dev/null || { echo "mas not found: run ../brew/install.sh essential first." >&2; exit 1; }

    local tmp line id rest name count=0
    tmp="$(mktemp)"

    log "Reading installed App Store apps (mas list)"
    # One tab-separated row per app:  category <TAB> id <TAB> name
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        read -r id rest <<< "$line"
        # Remove the trailing "(version)" from the rest of the line to get the name.
        name="$(printf '%s' "$rest" | sed -E 's/[[:space:]]+\([^)]*\)[[:space:]]*$//')"
        printf '%s\t%s\t%s\n' "$(app_category "$id")" "$id" "$name" >> "$tmp"
        count=$((count + 1))
    done < <(mas list)

    if [ "$count" -eq 0 ]; then
        rm -f "$tmp"
        warn "mas list printed nothing (is the App Store signed in?)"
        finish
        return
    fi

    {
        echo "# $(basename "$OUT") -- App Store apps on $(computer_name "${1:-}"), by category. Made by list_installed.sh."
        echo "# Copy the lines you want into masfile/<group>.mas, then:  bash install.sh <group>"
        # Sort by category, then by name; print a "## category" header when the category changes.
        sort -t "$(printf '\t')" -k1,1 -k3,3 "$tmp" | awk -F '\t' '
            $1 != last { print ""; print "## " $1; last = $1 }
            { printf "%s  %s\n", $2, $3 }'
    } > "$OUT"
    rm -f "$tmp"

    cat "$OUT"
    echo
    log "$count apps -> $OUT"
}

main "$@"
