# lib.sh - helpers shared by every script under bootstrap/ (1_first_step, 2_install_apps ...)
# and by the Mac settings scripts in setup_mac/_Mac (setup/1_run.sh, setup/2_sudorun.sh, setup/3_manual.sh) and setup_mac/_Finder/right_click/run.sh, which source it
# by its fixed place: $HOME/github/prosseek/bootstrap/bootstrap/_common/lib.sh
# Source it; do not run it. A function used by more than one script belongs here.
#
# Each step prints its result right after it runs, and finish() prints a summary table:
#   OK       done (a `defaults write` is read back and compared)
#   FAIL     something went wrong; the reason is listed under "Failed steps"
#   SKIP     intentionally not run (e.g. no computer name given)
#   No Auto  cannot be automated; do it by hand as written in readme.md
#
# Do not use `set -e` in the scripts: one failed step must not stop the others.

FAILED=()    # reasons of failures
MANUAL=()    # [No Auto] instructions
RESULTS=()   # "STATUS|number|label", for the summary table

if [ -t 1 ]; then
    C_OK=$'\033[32m'; C_FAIL=$'\033[31m'; C_WARN=$'\033[33m'; C_OFF=$'\033[0m'
else
    C_OK=''; C_FAIL=''; C_WARN=''; C_OFF=''
fi

log()  { echo "==> $*"; }
warn() { echo "${C_FAIL}!!  $*${C_OFF}" >&2; FAILED+=("$*"); }

require_mac_user() {
    [ "$(uname -s)" = "Darwin" ] || { echo "This script is for macOS." >&2; exit 1; }
    [ "$(id -u)" -ne 0 ]        || { echo "Do not run as root (brew refuses). Run as yourself." >&2; exit 1; }
}

paint() {   # paint STATUS -> colored status text, padded to 7 characters
    case "$1" in
        OK)   printf '%s%-7s%s' "$C_OK"   "$1" "$C_OFF" ;;
        FAIL) printf '%s%-7s%s' "$C_FAIL" "$1" "$C_OFF" ;;
        *)    printf '%s%-7s%s' "$C_WARN" "$1" "$C_OFF" ;;
    esac
}

# run_step NUMBER LABEL FUNCTION
# The function returns 2 to say SKIP, or 3 to say [No Auto] (it adds its own line to MANUAL first).
# A warn() inside it, or any other non-zero return, is FAIL.
run_step() {
    local num="$1" label="$2" fn="$3" before="${#FAILED[@]}" rc status
    "$fn"; rc=$?
    if   [ "$rc" -eq 2 ]; then status="SKIP"
    elif [ "$rc" -eq 3 ]; then status="No Auto"
    elif [ "$rc" -ne 0 ] || [ "${#FAILED[@]}" -gt "$before" ]; then status="FAIL"
    else status="OK"
    fi
    [ "$status" = FAIL ] && [ "${#FAILED[@]}" -eq "$before" ] && FAILED+=("[$num] $label: returned $rc")
    RESULTS+=("$status|$num|$label")
    echo "    -> [$num] $(paint "$status") $label"
}

# manual NUMBER LABEL INSTRUCTION: a [No Auto] step; the instruction is printed at the end.
manual() {
    RESULTS+=("No Auto|$1|$2")
    MANUAL+=("$1  $3")
    echo "    -> [$1] $(paint 'No Auto') $2"
}

# set_default DOMAIN KEY -TYPE VALUE
# defaults write, then read it back and compare. A mismatch is a failure.
set_default() {
    local domain="$1" key="$2" type="$3" value="$4" expected actual
    defaults write "$domain" "$key" "$type" "$value" || { warn "defaults write $domain $key"; return 1; }
    case "$type" in
        -bool) [ "$value" = true ] && expected=1 || expected=0 ;;
        *)     expected="$value" ;;
    esac
    actual="$(defaults read "$domain" "$key" 2>/dev/null)"
    if [ "$actual" = "$expected" ]; then
        echo "    ok  $domain $key = $actual"
    else
        warn "$domain $key: expected '$expected', got '${actual:-(unset)}'"
    fi
}

# check NUMBER LABEL COMMAND... : OK if the command succeeds, otherwise a failure
check() {
    local num="$1" label="$2"; shift 2
    if "$@" > /dev/null 2>&1; then echo "    ok  $label"; else warn "[$num] $label is not installed"; fi
}

# Put brew on PATH for this script (Apple Silicon, then Intel). Returns 1 if brew is not installed.
load_brew() {
    local b
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$b" ] && { eval "$("$b" shellenv)"; return 0; }
    done
    return 1
}

# Install Homebrew when it is missing, and put brew on PATH for this script.
# Safe to re-run: does nothing when brew is already installed.
# `brew` itself needs no sudo, but its installer creates /opt/homebrew as an administrator.
# The password is asked here (sudo -v), so NONINTERACTIVE=1 can run the installer without more questions.
# PATH for later shells comes from setup's zprofile (it has /opt/homebrew/bin).
ensure_brew() {
    load_brew && return 0
    log "Homebrew is not installed: installing it"
    sudo -v || { warn "Homebrew installer needs the administrator password (sudo failed)"; return 1; }
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || { warn "Homebrew install failed"; return 1; }
    load_brew || { warn "Homebrew installed, but brew was not found afterwards"; return 1; }
}

# computer_name [GIVEN]: the computer name used in file names (installed.<computer>.txt).
#   GIVEN if one was passed, otherwise LocalHostName, otherwise `hostname -s`.
#   Lower-cased; anything but letters, digits, "-" and "_" becomes "-" (safe in a file name).
computer_name() {
    local name="${1:-}"
    [ -n "$name" ] || name="$(scutil --get LocalHostName 2>/dev/null)"
    [ -n "$name" ] || name="$(hostname -s)"
    printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'
}

# --- categories: one list file per category, e.g. essential.brewfile, essential.mas ---
# categories/run_categories: files named "PREFIX.name". categories_ext/run_categories_ext: files named "name.EXT".

# categories DIR PREFIX: print every category name found in DIR, one per line.
#   The glob lists the files. If nothing matches, bash leaves the pattern as plain text,
#   so -f (is it a regular file?) filters that case out.
categories() {
    local dir="$1" prefix="$2" f
    for f in "$dir/$prefix".*; do
        [ -f "$f" ] && echo "${f##*/$prefix.}"    # keep only what follows "PREFIX."
    done
}

# CURRENT = the category being processed. run_step calls a function without arguments,
# so the function reads the category from this global variable.
CURRENT=""

# run_categories DIR PREFIX FUNCTION [CATEGORY]
# Run FUNCTION once for the given category, or once for every category when none is given.
# FUNCTION finds its file as "$DIR/$PREFIX.$CURRENT". Each run is one row in the summary table.
run_categories() {
    local dir="$1" prefix="$2" fn="$3" list c
    # $4 given: only that one. Not given: all of them (newlines turned into spaces).
    list="${4:-$(categories "$dir" "$prefix" | tr '\n' ' ')}"
    # $list is not quoted on purpose: bash splits it at the spaces, one loop turn per category.
    for c in $list; do
        CURRENT="$c"
        run_step "$c" "$prefix.$c" "$fn"
    done
}

# categories_ext DIR EXT: like categories, for files named "<category>.EXT" (essential.brewfile -> essential).
categories_ext() {
    local dir="$1" ext="$2" f
    for f in "$dir"/*."$ext"; do
        [ -f "$f" ] && { f="${f##*/}"; echo "${f%."$ext"}"; }
    done
}

# run_categories_ext DIR EXT FUNCTION [CATEGORY]: like run_categories, for "<category>.EXT" files.
# FUNCTION finds its file as "$DIR/$CURRENT.EXT".
run_categories_ext() {
    local dir="$1" ext="$2" fn="$3" list c
    list="${4:-$(categories_ext "$dir" "$ext" | tr '\n' ' ')}"
    for c in $list; do
        CURRENT="$c"
        run_step "$c" "$c.$ext" "$fn"
    done
}

# --- System Settings panes: open several panes in a row, so the back button (<-) walks through them ---
# Used by setup_mac/_Mac/setup/3_manual.sh and setup_mac/_Finder/right_click/run.sh.
# A step calls queue_pane (once per pane) and add_manual (its instruction); main calls open_panes
# after the last step and before finish.

PANE_DELAY=0.5   # seconds between two `open` calls
PANES=()         # URLs to open, in step order (see open_panes)
PANE_STEPS=()    # PANE_STEPS[i] = the step number that PANES[i] belongs to

# queue_pane STEP URL: remember a pane (open_panes opens them all at the end)
# and show the command that opens it.
queue_pane() {
    PANE_STEPS+=("$1")
    PANES+=("$2")
    echo "    open \"$2\""
}

# add_manual STEP TEXT: add the instruction to the final list, followed by the
# open command of every pane queued for this step (none for steps without a pane).
add_manual() {
    local step="$1" text="$2" entry i
    entry="$step  $text"
    for i in ${PANES[@]+"${!PANES[@]}"}; do
        [ "${PANE_STEPS[$i]}" = "$step" ] && entry+=$'\n'"      open \"${PANES[$i]}\""
    done
    MANUAL+=("$entry")
}

# open_panes: open every queued pane, PANE_DELAY seconds apart, and print each command.
# Reverse order: the first queued pane is opened last, so it stays on screen and the
# back button (<-) goes to the next one.
open_panes() {
    local i n="${#PANES[@]}"
    [ "$n" -gt 0 ] || return 0

    # `open` calls that arrive while System Settings is still starting may be lost, so start it first.
    if ! pgrep -x "System Settings" > /dev/null 2>&1; then
        open -a "System Settings" > /dev/null 2>&1 || true
        sleep 2
    fi

    log "Opening $n System Settings panes, ${PANE_DELAY}s apart (use the back button <- to go on)"
    for (( i = n - 1; i >= 0; i-- )); do
        echo "    [${PANE_STEPS[$i]}] open \"${PANES[$i]}\""
        open "${PANES[$i]}" > /dev/null 2>&1 || warn "could not open ${PANES[$i]}"
        sleep "$PANE_DELAY"
    done
}

# finish [TRAILER...]: print the summary table, the [No Auto] list and the failures; exit 1 on failure.
finish() {
    local row status num label
    echo
    echo "================ Summary ================"
    for row in ${RESULTS[@]+"${RESULTS[@]}"}; do
        IFS='|' read -r status num label <<< "$row"
        printf '  [%-4s] %s  %s\n' "$num" "$(paint "$status")" "$label"
    done
    echo "========================================="

    if [ "${#MANUAL[@]}" -gt 0 ]; then
        echo
        echo "[No Auto] Do these by hand (same numbers as readme.md):"
        printf '  %s\n' "${MANUAL[@]}"
    fi
    [ "$#" -gt 0 ] && { echo; printf '%s\n' "$@"; }

    if [ "${#FAILED[@]}" -gt 0 ]; then
        echo
        echo "${C_FAIL}Failed steps:${C_OFF}" >&2
        printf '  - %s\n' "${FAILED[@]}" >&2
        exit 1
    fi
    log "Done: no failures"
}
