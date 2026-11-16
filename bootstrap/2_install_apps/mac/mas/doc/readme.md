# mas - App Store apps

Install App Store apps with the `mas` command (installed by `../brew`, `essential.brewfile`).
The App Store must be signed in first. That cannot be automated.

## What is `mas`

`mas` is a command line tool for the Mac App Store. An App Store app is identified by a number (its App Store id), not by its name.

```
mas list                  # installed App Store apps: id, name, version
mas search MagicGlance    # search the App Store
mas install 6449926189    # install by id (MagicGlance)
```

## Install: `install.sh`

One `masfile/<group>.mas` per group (all in the `masfile/` folder), one line per app: `<App Store id>  <name>` (the name is only for reading).

```
bash install.sh                # no argument: only essential.mas
bash install.sh essential      # the same, written out
bash install.sh productivity   # only productivity.mas
bash install.sh all            # every *.mas
```

- No argument installs **only `essential`**. Only the word `all` installs every group, which is a lot of apps.
- It prints `skip` / `installed` / `FAIL` per app. Safe to re-run: what is installed is skipped.
- To add a group, create `masfile/<name>.mas`. `install.sh` does not change.
- `run.sh` calls `bash install.sh essential`.

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
2. Copy the lines you want into `masfile/<group>.mas` (e.g. `work.mas`, `media.mas`).
3. On the new Mac: sign in to the App Store, then `bash install.sh work`.

The category comes from the App Store data stored in each app (`mdls -name kMDItemAppStoreCategory`).
An app that Spotlight cannot find is listed under `## Unknown`; move it by hand.

## How was an app installed? (App Store, brew or by hand)

```
mas list | grep -i NAME                 # App Store app: shown with its id
brew list --cask | grep -i NAME         # installed as a Homebrew cask
ls -d /Applications/NAME.app            # where the app is
```

In the App Store: it is in `mas list`, and its id is in a Masfile (e.g. `6449926189  MagicGlance` in `productivity.mas`).
Not in either list: the app was downloaded by hand.

## Not in the App Store, not in brew

Put those in `../manual` (see `../manual/readme.md`).

## Read Apple ID

AppleScript: `osascript -e 'id of app "TextMate"'`
앱 경로로 직접 읽기: `mdls -name kMDItemCFBundleIdentifier /Applications/TextMate.app`
Info.plist에서 읽기: `defaults read /Applications/TextMate.app/Contents/Info CFBundleIdentifier`
