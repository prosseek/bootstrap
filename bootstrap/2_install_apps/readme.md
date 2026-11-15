# Install apps

Install apps with Homebrew, one category at a time. Run `1_first_step/mac/2_run.sh` first (it installs Homebrew).

## mac/brew

One `brewfile/Brewfile.<category>` per category (all in the `brewfile/` folder), and one script that installs them.

```
cd mac/brew
bash install.sh essential   # only brewfile/Brewfile.essential
bash install.sh             # no argument: every brewfile/Brewfile.*
```

For every line of a Brewfile the script prints what it did:

```
    skip       cask "claude"                      <- already installed, nothing done
    installed  cask "visual-studio-code"          <- was missing, installed now
!!  [essential] FAIL: cask "typora"              <- could not be installed
    -> 1 installed, 1 skipped, 1 failed
```

* Each category then gets `OK` (no FAIL) or `FAIL`, and a summary table is printed at the end.
* Safe to re-run: what is installed is skipped.
* To add a category, create `Brewfile.<name>` in `mac/brew/brewfile/`. Nothing else to change.
* To see what the current Mac has, run `bash list_installed.sh` in `mac/brew/`: it writes `installed/installed.<computer>.txt` (e.g. `installed/installed.m4.txt`) with the taps, formulae and casks you installed, each with its description. Copy the lines you want into `brewfile/Brewfile.<category>`. It uses `brew bundle dump`, and App Store apps are not in it (see `mac/mas`).
* Both `install.sh` use the helpers in `bootstrap/_common/lib.sh`.

| Category | Contents |
|---|---|
| `essential` | python@3.14, mas, VSCode, Claude |

## mac/mas

App Store apps, installed with the `mas` command (installed by `brew`'s `essential`).
They are separate because they need the App Store to be signed in, which cannot be automated.

```
# 1. [No Auto] open the App Store and sign in
# 2. then:
cd mac/mas
bash install.sh essential   # only masfile/Masfile.essential
bash install.sh             # no argument: every masfile/Masfile.*
```

One app per line of `masfile/Masfile.<category>`: `<App Store id>  <name>` (the name is only for reading).
It prints `skip` / `installed` / `FAIL` per app, like `brew`. If an app fails, check the sign-in and re-run.

| Category | Contents |
|---|---|
| `essential` | Bear |
| `developer-tools`, `finance`, `markdown`, `microsoft`, `apple`, `editor`, `books`, `social-networking`, `utilities`, `language`, `productivity`, `notes`, `education` | made from the `installed/installed.<computer>.txt` lists (one group per field) |

To see what the current Mac has, run `bash list_installed.sh` (writes `installed/installed.<computer>.txt`, grouped by App Store category), then copy the lines you want into `Masfile.<group>`. Details: `mac/mas/readme.md`.

The old all-in-one list is `_old/x_install/mac/Brewfile`. Move its items into the categories a little at a time.

## mac/manual

Apps that neither brew nor mas can install (a vendor download, a license ...). They cannot be automated, so the folder has no script, only `mac/manual/readme.md`: a list of the apps and how to install each one by hand.

