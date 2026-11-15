#!/usr/bin/env bash
#
# 4_email.sh - Part 4 of readme.md: e-mail accounts (Apple, Microsoft/NKU, Google).
#
# What can be automated here is small, and this script says so:
#   1  Apple Account   only a CHECK: is an Apple Account signed in?       (OK or No Auto)
#   2  Microsoft (NKU) [No Auto]: school login (SSO + MFA) needs you
#   3  Google accounts [No Auto]: the script opens Internet Accounts and lists the addresses
#                      from accounts.txt; every account needs its own browser login (OAuth)
# Adding an account needs a password and a second factor / browser login, and macOS has no
# supported command for that. (A configuration profile does not help: the Google account
# payload is iOS-only and macOS ignores it.)
#
# Usage:
#   bash 4_email.sh
#
# Safe to re-run: it changes nothing, it only checks and lists what is left for you.
# Step numbers are the same as in Part 4 of readme.md.
set -u
# Shared helpers (log, run_step, manual, finish ...) live in bootstrap/_common/lib.sh.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../../_common/lib.sh"
require_mac_user

# The Internet Accounts pane has a different name before macOS 13 (System Preferences era).
# On a school-managed Mac the pane may be hidden by policy; then use Mail -> Add Account...
macos_major="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
if [ "${macos_major:-0}" -ge 13 ]; then
    INTERNET_ACCOUNTS="x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension"
else
    INTERNET_ACCOUNTS="x-apple.systempreferences:com.apple.preferences.internetaccounts"
fi
# Is this Mac managed by a school/company (MDM)? A managed Mac may hide the Internet Accounts pane.
MANAGED=no
profiles status -type enrollment 2>/dev/null | grep -qi 'MDM enrollment: *Yes' && MANAGED=yes
FALLBACK="If the pane does not open or is missing: open Mail -> menu Mail -> Add Account..."

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

# ---------------------------------------------------------------------------
# 3. Google accounts: the login cannot be scripted, so help with the rest.
# Read the addresses from accounts.txt (one per line, # lines and empty lines ignored), print
# them, and open Internet Accounts so you can add them one after another.
# ---------------------------------------------------------------------------
step_3_google_accounts() {
    log "[3] Google accounts"
    local list="$DIR/accounts.txt" email emails="" count=0

    if [ -f "$list" ]; then
        while IFS= read -r email; do
            case "$email" in ""|"#"*) continue ;; esac
            echo "    $email"
            emails="$emails${emails:+, }$email"
            count=$((count + 1))
        done < "$list"
    fi

    if [ "$count" -eq 0 ]; then
        MANUAL+=("3  Google: open \"$INTERNET_ACCOUNTS\" -> Add Account -> Google -> sign in (password + 2-step) -> choose Mail. Repeat for every account. $FALLBACK (Optional: list the addresses in accounts.txt next to this script.)")
        return 3
    fi

    open_accounts_ui   # convenience only; failure is not an error
    MANUAL+=("3  Google ($count accounts): in Internet Accounts -> Add Account -> Google, once for each: $emails -> sign in (password + 2-step) -> choose Mail. $FALLBACK")
    return 3    # the login itself is [No Auto]
}

# Open Internet Accounts, and also Mail on a managed Mac (Mail -> Add Account... works there).
open_accounts_ui() {
    open "$INTERNET_ACCOUNTS" >/dev/null 2>&1 || true
    [ "$MANAGED" = yes ] && open -a Mail >/dev/null 2>&1 || true
}

main() {
    echo "macOS $(sw_vers -productVersion 2>/dev/null) | managed (MDM): $MANAGED | pane: ${INTERNET_ACCOUNTS#x-apple.systempreferences:}"
    run_step 1 "Apple Account signed in" step_1_apple_account

    manual 2 "Microsoft (NKU) account" "Microsoft: open \"$INTERNET_ACCOUNTS\" -> Add Account -> Microsoft Exchange -> sign in with the NKU account (school login + MFA) -> choose Mail (and Calendars, Contacts if wanted). $FALLBACK"
    run_step 3 "Google accounts (from accounts.txt)" step_3_google_accounts

    finish "$FALLBACK"
}

main "$@"
