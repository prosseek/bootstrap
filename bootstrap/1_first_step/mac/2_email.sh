#!/usr/bin/env bash
#
# 2_email.sh - Part 2 of readme.md: iCloud (Apple Account) only.
#
# What can be automated here is small, and this script says so:
#   1  Apple Account   only a CHECK: is an Apple Account signed in?       (OK or No Auto)
# Signing in needs a password and a second factor, and macOS has no supported command for it.
# The other mail accounts (Microsoft/NKU, Google) are in
# ~/github/prosseek/setup_mac/_ManualSetup/_email_setup/email.sh (see email.sh.md there).
#
# Usage:
#   bash 2_email.sh
#
# Safe to re-run: it changes nothing, it only checks and lists what is left for you.
# Step numbers are the same as in Part 2 of readme.md.
set -u
# Shared helpers (log, run_step, manual, finish ...) live in bootstrap/_common/lib.sh.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../_common/lib.sh"
require_mac_user

# ---------------------------------------------------------------------------
# 1. Apple Account: is somebody signed in?
# macOS keeps the signed-in Apple Account in the MobileMeAccounts preferences; each account
# there has an AccountID (the e-mail address). Only reading is done here. If nothing is found
# (or the layout differs on this macOS) the step is [No Auto]; it never reports OK by mistake.
# ---------------------------------------------------------------------------
step_1_apple_account() {
    log "[1] Apple Account"
    local ids
    # awk -F'"' splits at double quotes: the line  AccountID = "me@icloud.com";  -> field 2.
    ids="$(defaults read MobileMeAccounts Accounts 2>/dev/null | awk -F'"' '/AccountID/ { print $2 }' | sort -u)"

    if [ -n "$ids" ]; then
        echo "    signed in: $ids"
        return 0
    fi

    MANUAL+=('1  Apple Account: open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings?iCloud" -> sign in -> iCloud -> turn on Mail')
    return 3    # [No Auto]
}

main() {
    echo "macOS $(sw_vers -productVersion 2>/dev/null)"
    run_step 1 "Apple Account signed in" step_1_apple_account

    finish
}

main "$@"
