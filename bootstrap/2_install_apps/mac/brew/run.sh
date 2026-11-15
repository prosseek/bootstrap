#!/usr/bin/env bash

# Go to the folder of this script first, so it works from anywhere
# (TextMate and others run scripts from another folder).
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

bash install.sh essential   # only brewfile/Brewfile.essential

#bash install.sh             # every brewfile/Brewfile.*
