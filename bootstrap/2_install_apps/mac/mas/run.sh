#!/usr/bin/env bash

# Go to the folder of this script first, so it works from anywhere
# (TextMate and others run scripts from another folder).
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# mas 4.0.0+ needs root to install apps, so `mas install` asks for the administrator password.
# A script started from TextMate/Finder has no terminal, so the password cannot be asked.
# Relaunch in Terminal first. The child has a TTY and can show the normal password prompt.
if [ ! -t 0 ] || [ ! -t 1 ]; then
  relaunch_command="cd $(printf '%q' "$PWD") && exec /bin/bash $(printf '%q' "${BASH_SOURCE[0]}")"
  RUN_MAS_RELAUNCH_COMMAND="$relaunch_command" osascript \
    -e 'tell application "Terminal" to do script (system attribute "RUN_MAS_RELAUNCH_COMMAND")' \
    -e 'tell application "Terminal" to activate'
  exit $?
fi

# Ask once at the beginning, rather than in the middle of the app list.  mas uses the
# sudo credentials that already exist. The keep-alive process refreshes sudo's timestamp
# (every 60 seconds) without ever prompting again, so a long download cannot make it expire.
if ! sudo -v; then
  echo "Administrator authentication is required to install App Store apps with mas." >&2
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

# Not "exec": the trap above must run after install.sh ends, to stop the keep-alive process.
bash install.sh essential   # only masfile/essential.mas (same as: bash install.sh)

#bash install.sh all         # every masfile/*.mas
