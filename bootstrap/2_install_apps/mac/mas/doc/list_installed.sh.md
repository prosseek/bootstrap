# mas - App Store apps

Install App Store apps with the `mas` command (installed by `../brew`, `Brewfile.essential`).
The App Store must be signed in first. That cannot be automated.

## Install: `install.sh`

One `masfile/Masfile.<group>` per group (all in the `masfile/` folder), one line per app: `<App Store id>  <name>` (the name is only for reading).

```
bash install.sh essential   # only Masfile.essential
bash install.sh             # no argument: every Masfile.*
```

It prints `skip` / `installed` / `FAIL` per app. Safe to re-run. To add a group, create `masfile/Masfile.<name>`.
No argument installs every group, which is a lot of apps: prefer one group at a time.

## Find what is installed now: `list_installed.sh`

Run it on the Mac that already has the apps. It reads `mas list`, asks Spotlight for each
app's App Store category, and writes `installed/installed.<computer>.txt`, grouped by category.
The computer name is in the file name so that every Mac keeps its own list in the `installed/` folder.

```
bash list_installed.sh        # <computer> = LocalHostName, e.g. installed/installed.m5.txt
bash list_installed.sh m5     # or give the name yourself
```

The name is lower-cased, and anything but letters, digits, `-` and `_` becomes `-`.

```
## Developer Tools
497799835  Xcode

## Productivity
1091189122  Bear
```

`installed/installed.<computer>.txt` is a report that is overwritten when the same Mac runs again, and `install.sh` never reads it.
To get the apps on a new Mac:

1. Run `bash list_installed.sh` on the old Mac (and on every other Mac you want to compare).
2. Copy the lines you want into `masfile/Masfile.<group>` (e.g. `Masfile.work`, `Masfile.media`).
3. On the new Mac: sign in to the App Store, then `bash install.sh work`.

The category comes from the App Store data stored in each app (`mdls -name kMDItemAppStoreCategory`).
An app that Spotlight cannot find is listed under `## Unknown`; move it by hand.

## Not in the App Store, not in brew

Put those in `../manual` (see `../manual/readme.md`).
