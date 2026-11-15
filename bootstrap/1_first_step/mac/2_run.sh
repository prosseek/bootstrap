#!/usr/bin/env bash
#
# 2_run.sh - Part 2 of readme.md: first-time setup of a new Mac, everything that needs no sudo.
# Run 1_hostname.sh (Part 1) first if you want to set the computer name.
# Homebrew is the last step here: the other apps are installed with brew afterwards, all at once.
#
# Usage:
#   bash 1_hostname.sh
#   bash 2_run.sh
#
# Safe to re-run. The step numbers (1 ... 9, and 4.1, 7.2) are the same as in Part 2
# of readme.md. Steps that cannot be automated are [No Auto]; they are listed again at the end.
#
# Only the Homebrew installer (step 9) needs the administrator password: this script asks
# for it just before the installer, and only when Homebrew is not installed yet.
set -u
# Shared helpers (log, warn, run_step, check, finish ...) live in bootstrap/_common/lib.sh.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_common/lib.sh"
require_mac_user

# ---------------------------------------------------------------------------
# 1, 2, 3 are [No Auto]: see main()
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 4. Keyboard (4.1 input sources is [No Auto]: see main())
# ---------------------------------------------------------------------------
step_4_2_smart_quotes() {
    log "[4.2] Keyboard: smart quotes and dashes off"
    set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled  -bool false
}

# ---------------------------------------------------------------------------
# 5. Mouse, 6. Trackpad
# Built-in and Bluetooth devices use different domains, so write both.
# A logout (or restart) is needed before the change shows up.
# ---------------------------------------------------------------------------
step_5_mouse() {
    log "[5] Mouse: secondary click on the right side"
    set_default com.apple.AppleMultitouchMouse                  MouseButtonMode -string TwoButton
    set_default com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string TwoButton
}

step_6_trackpad() {
    log "[6] Trackpad: drag with drag lock"
    local d
    for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
        set_default "$d" Dragging -bool true
        set_default "$d" DragLock -bool true
    done
}

# ---------------------------------------------------------------------------
# 7. Finder (7.2 folders already opened is [No Auto]: see main())
# ---------------------------------------------------------------------------
step_7_1_finder_list_view() {
    log "[7.1] Finder: list view by default"
    set_default com.apple.finder FXPreferredViewStyle -string "Nlsv"
    killall Finder 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 8. TextEdit: plain text, no auto substitution
# ---------------------------------------------------------------------------
step_8_textedit() {
    log "[8] TextEdit: plain text, no auto substitution"
    set_default com.apple.TextEdit SmartQuotes     -bool false
    set_default com.apple.TextEdit SmartDashes     -bool false
    set_default com.apple.TextEdit SmartLinks      -bool false
    set_default com.apple.TextEdit TextReplacement -bool false
    set_default com.apple.TextEdit RichText        -int 0
}

# ---------------------------------------------------------------------------
# 9. Homebrew. Only brew itself: the other apps (mas, Bear, VSCode, Claude, Python ...)
# are installed with brew afterwards, all at once.
# ---------------------------------------------------------------------------
step_9_brew() {
    log "[9] Homebrew"
    if ! load_brew; then
        # `brew` itself needs no sudo, but its installer creates /opt/homebrew as an administrator.
        # Ask for the password here, so NONINTERACTIVE=1 can run the installer without more questions.
        sudo -v || { warn "[9] sudo failed: Homebrew installer needs the administrator password"; return; }
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            || warn "[9] Homebrew install"
        load_brew
    fi
    # PATH for later shells comes from setup's zprofile (it has /opt/homebrew/bin).
    check 9 "brew" command -v brew
}

main() {
    # Same order and numbers as Part 2 of readme.md.
    manual 1     "Apple Account, iCloud"  'Apple Account, iCloud, Desktop & Documents: open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings?iCloud"'
    manual 2     "Edit Widget"            'Edit Widget: Ctrl + Click on a widget'
    manual 3     "Touch ID, Apple Watch"  'Apple Watch unlock and Touch ID: open "x-apple.systempreferences:com.apple.Touch-ID-Settings.extension"'
    manual 4.1   "Keyboard input sources" 'Input Sources, add Korean and Japanese: open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"'
    run_step 4.2 "Keyboard: no smart quotes" step_4_2_smart_quotes
    run_step 5   "Mouse: secondary click"    step_5_mouse
    run_step 6   "Trackpad: drag lock"       step_6_trackpad
    run_step 7.1 "Finder: list view"         step_7_1_finder_list_view
    manual 7.2   "Finder: folders already opened" 'Folders you already opened: Cmd-2, Cmd-J, "Always open in list view", "Use as Defaults"'
    run_step 8   "TextEdit"                  step_8_textedit
    run_step 9   "Homebrew"                  step_9_brew

    finish "Also: log out and in again so the mouse (5) and trackpad (6) changes take effect."
}

main "$@"
