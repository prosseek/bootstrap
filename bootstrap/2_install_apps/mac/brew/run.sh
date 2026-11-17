#!/usr/bin/env bash

# Go to the folder of this script first, so it works from anywhere
# (TextMate and others run scripts from another folder).
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Some casks (for example BasicTeX) run the macOS installer with sudo.  A script
# started from TextMate/Finder has no terminal, so sudo cannot ask for the
# administrator password.  Relaunch in Terminal before invoking Homebrew.
# The child has a TTY and can show sudo's normal password prompt when needed.
if [ ! -t 0 ] || [ ! -t 1 ]; then
  relaunch_command="cd $(printf '%q' "$PWD") && exec /bin/bash $(printf '%q' "${BASH_SOURCE[0]}")"
  RUN_BREW_RELAUNCH_COMMAND="$relaunch_command" osascript \
    -e 'tell application "Terminal" to do script (system attribute "RUN_BREW_RELAUNCH_COMMAND")' \
    -e 'tell application "Terminal" to activate'
  exit $?
fi

# brew in /opt/homebrew refuses to run under Rosetta ("Cannot install under Rosetta 2").
# A program started by a Rosetta (Intel) app, such as TextMate, passes x86_64 down to its shell.
# So if this shell is x86_64 on an Apple Silicon Mac, restart it as ARM.
# hw.optional.arm64 is 1 only on Apple Silicon; the variable stops an endless restart loop.
if [ "$(uname -m)" = "x86_64" ] && [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ] \
   && [ -z "${BREW_RUN_ARM_RESTART:-}" ]; then
  echo "Started under Rosetta (x86_64): restarting as arm64."
  BREW_RUN_ARM_RESTART=1 exec arch -arm64 /bin/bash "${BASH_SOURCE[0]}" "$@"
fi

# BasicTeX invokes the macOS installer with sudo.  Ask once at the beginning,
# rather than interrupting the installation when that cask is reached.  The
# keep-alive process refreshes sudo's timestamp without ever prompting again.
if ! sudo -v; then
  echo "Administrator authentication is required to install BasicTeX." >&2
  exit 1
fi

(
  while true; do
    sudo -n -v 2>/dev/null || exit
    sleep 60
  done
) &
sudo_keepalive_pid=$!
trap 'kill "$sudo_keepalive_pid" 2>/dev/null || true' EXIT

# Install Homebrew itself first when it is missing (ensure_brew is in bootstrap/_common/lib.sh).
# sudo is already unlocked above, so this asks for no second password.
source "$PWD/../../../_common/lib.sh"
ensure_brew || { echo "Homebrew is not available: cannot install apps." >&2; exit 1; }


bash install.sh essential   # only brewfile/essential.brewfile

#bash install.sh             # every brewfile/*.brewfile
