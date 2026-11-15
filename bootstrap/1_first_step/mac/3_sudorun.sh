#!/usr/bin/env bash
#
# 3_sudorun.sh - Part 3 of readme.md: the steps that need sudo (administrator password).
# Every sudo step added from now on goes here.
#
#   1  Remote Login (SSH): let other computers ssh into this Mac
#   2  Remote Login access: make sure the account running this script may log in
#
# Usage:
#   bash 3_sudorun.sh      (as yourself, not with sudo)
#
# Safe to re-run. The password is asked only when a step has something to change.
# Step numbers are the same as in Part 3 of readme.md.
set -u
# Shared helpers (log, warn, run_step, check, finish ...) live in bootstrap/_common/lib.sh.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_common/lib.sh"
require_mac_user

# ---------------------------------------------------------------------------
# 1. Remote Login (SSH)
# Needs the terminal app to have Full Disk Access; if not, this is a [No Auto] step.
# Turning it on only opens the door: logging in without a password still needs
# the other computer's public key in ~/.ssh/authorized_keys.
# ---------------------------------------------------------------------------
ssh_is_on() { nc -z -w 2 localhost 22 > /dev/null 2>&1; }

step_1_remote_login() {
    log "[1] Remote Login (SSH)"
    if ssh_is_on; then echo "    already on"; return 0; fi

    sudo -v || { warn "[1] sudo failed"; return 1; }
    local out i
    out="$(sudo systemsetup -setremotelogin on 2>&1)"
    for i in 1 2 3 4 5; do ssh_is_on && { echo "    ok  port 22 is open"; return 0; }; sleep 1; done

    # systemsetup may print the reason and still exit 0, so judge by the port, not the exit status.
    echo "    systemsetup: ${out:-(no output)}"
    case "$out" in
        *"Full Disk Access"*)
            MANUAL+=('1  Remote Login: open "x-apple.systempreferences:com.apple.Sharing-Settings.extension" -> turn on Remote Login (or give the terminal Full Disk Access and re-run)')
            return 3 ;;   # [No Auto]
    esac
    warn "[1] Remote Login is still off: $out"
}

# ---------------------------------------------------------------------------
# 2. Who may log in over SSH ("Allow access for" in the Remote Login settings)
# "All users" = the group com.apple.access_ssh does not exist.
# "Only these users" = that group exists; anyone outside it is disconnected right after
# typing the password ("Connection closed by ... port 22").
# This step never opens SSH to everybody: it only adds the current account to the list
# when the list exists and the account is not in it.
# To allow everybody instead (not done here): sudo dseditgroup -o delete com.apple.access_ssh
# ---------------------------------------------------------------------------
SSH_GROUP="com.apple.access_ssh"

ssh_user_allowed() {   # checkmember also sees nested groups (e.g. Administrators)
    dseditgroup -o checkmember -m "$USER" "$SSH_GROUP" 2>&1 | grep -q '^yes'
}

step_2_ssh_access() {
    log "[2] Remote Login access for $USER"
    if ! dseditgroup -o read "$SSH_GROUP" > /dev/null 2>&1; then
        echo "    All users may log in (no $SSH_GROUP list)"
        return 0
    fi
    if ssh_user_allowed; then echo "    $USER is in the allowed list"; return 0; fi

    sudo -v || { warn "[2] sudo failed"; return 1; }
    sudo dseditgroup -o edit -a "$USER" -t user "$SSH_GROUP" || { warn "[2] dseditgroup: cannot add $USER"; return 1; }
    if ssh_user_allowed; then echo "    ok  added $USER to the allowed list"; else warn "[2] $USER is still not allowed"; fi
}

main() {
    run_step 1 "Remote Login (SSH)"    step_1_remote_login
    run_step 2 "Remote Login access"   step_2_ssh_access

    finish
}

main "$@"
