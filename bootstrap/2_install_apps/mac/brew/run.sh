#!/usr/bin/env bash

# Go to the folder of this script first, so it works from anywhere
# (TextMate and others run scripts from another folder).
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# brew in /opt/homebrew refuses to run under Rosetta ("Cannot install under Rosetta 2").
# A program started by a Rosetta (Intel) app, such as TextMate, passes x86_64 down to its shell.
# So if this shell is x86_64 on an Apple Silicon Mac, restart it as ARM.
# hw.optional.arm64 is 1 only on Apple Silicon; the variable stops an endless restart loop.
if [ "$(uname -m)" = "x86_64" ] && [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ] \
   && [ -z "${BREW_RUN_ARM_RESTART:-}" ]; then
  echo "Started under Rosetta (x86_64): restarting as arm64."
  BREW_RUN_ARM_RESTART=1 exec arch -arm64 /bin/bash "${BASH_SOURCE[0]}" "$@"
fi


bash install.sh essential   # only brewfile/Brewfile.essential

#bash install.sh             # every brewfile/Brewfile.*
