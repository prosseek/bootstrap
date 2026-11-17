#!/usr/bin/env bash
#
# 1_hostname.sh - Part 1 of readme.md: the step that needs sudo (administrator password).
# Run this first.
#
#   1  Set hostname (asks for the name; Enter skips it, then no password is asked)
#
# Run it as yourself, not with sudo.
# The other Mac settings (1_run.sh, 2_sudorun.sh) moved to ~/github/prosseek/setup_mac/_Mac/setup
# and run with `bash ~/github/prosseek/setup_mac/runall.sh`.
#
# Usage:
#   bash 1_hostname.sh
#
# Safe to re-run. Step numbers are the same as in Part 1 of readme.md.
set -u
# Shared helpers (log, warn, run_step, check, finish ...) live in bootstrap/_common/lib.sh.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_common/lib.sh"
require_mac_user

# ---------------------------------------------------------------------------
# 1. Set hostname (asks the user; an empty answer skips it)
# ---------------------------------------------------------------------------
NAME=""

ask_hostname() {
    local current
    current="$(scutil --get ComputerName 2>/dev/null || echo '(not set)')"
    # read fails when there is no terminal (e.g. piped input): treat it as "skip".
    read -r -p "Computer name [now: $current] (Enter to skip): " NAME || NAME=""
}

step_1_hostname() {
    [ -n "$NAME" ] || { log "[1] No name given"; return 2; }
    log "[1] Computer name: $NAME"
    local n actual
    for n in ComputerName LocalHostName HostName; do
        sudo scutil --set "$n" "$NAME" || warn "[1] scutil --set $n"
    done
    for n in ComputerName LocalHostName HostName; do
        actual="$(scutil --get "$n" 2>/dev/null || echo '(not set)')"
        echo "    $n: $actual"
        [ "$actual" = "$NAME" ] || warn "[1] $n is '$actual', expected '$NAME'"
    done
}

main() {
    # Ask everything first, so the rest can run unattended.
    ask_hostname
    # Ask for the password once, and only when there is a name to set.
    if [ -n "$NAME" ]; then
        sudo -v || { echo "sudo failed" >&2; exit 1; }
    fi

    run_step 1 "Set hostname" step_1_hostname

    finish "Next: install the apps (bootstrap/2_install_apps/mac), then bash ~/github/prosseek/setup_mac/runall.sh"
}

main "$@"
