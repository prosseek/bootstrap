# Mac - First Step

Run the scripts in this order. Each part below matches one script, and the step numbers
are the same as the ones the script prints (`[4.2] OK ...`) and lists in its summary table.

```
bash 1_hostname.sh   # Part 1: computer name (needs sudo)
bash 2_run.sh        # Part 2: everything else
bash 3_sudorun.sh    # Part 3: more steps that need sudo (collects the sudo steps added from now on)
bash 4_email.sh      # Part 4: e-mail accounts (mostly manual)
```

* **Auto**: done by the script. **[No Auto]**: do it by hand, as written under the step.
* Summary status: `OK`, `FAIL`, `SKIP`, `No Auto`. A `defaults write` is read back to confirm it.
* All scripts are safe to re-run. The helpers they share are in `bootstrap/_common/lib.sh`.

---

# Part 1 - `1_hostname.sh` (needs sudo)

Run as yourself, not with `sudo`. The password is asked only when you give a name.

1. Set hostname (Auto; the script asks for the name, Enter skips it, e.g. on the NKU computer)
    1. Manual way: open "x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension" -> update the name
    2. Command:
        ```
        NAME="m5"
        sudo scutil --set ComputerName "$NAME"
        sudo scutil --set LocalHostName "$NAME"
        sudo scutil --set HostName "$NAME"
        for name in ComputerName LocalHostName HostName; do
            echo "$name: $(scutil --get "$name" 2>/dev/null || echo '(not set)')"
        done
        ```
    3. ComputerName: shown in Finder, AirDrop, Sharing. LocalHostName: the Bonjour/mDNS name on the local network. HostName: the Unix host name.
       On a normal Mac, changing the Name in About is enough. Set HostName only when a fixed Unix/server host name is needed.

---

# Part 2 - `2_run.sh`

No `sudo` except step 9: the Homebrew installer needs the administrator password (asked only when Homebrew is not installed yet). Log out and in again afterwards so the mouse and trackpad changes take effect.

1. [No Auto] Apple Account (+m2m4)
    1. Sign-in needs the password and two-factor code, and iCloud Drive "Desktop & Documents" has no defaults key.
    2. open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings?iCloud"
        1. iCloud -> turn on what you need
        2. iCloud Drive -> Desktop & Documents Folders
2. [No Auto] Edit Widget
    1. Ctrl + Click on Widget -> Edit Widgets. (Widgets are not controlled by `defaults`.)
3. [No Auto] Touch ID & Password
    1. Fingerprints must be scanned by you; Apple Watch unlock asks for your password.
    2. open "x-apple.systempreferences:com.apple.Touch-ID-Settings.extension"
        1. Apple Watch
        2. Touch ID
4. Keyboard
    1. [No Auto] Input Sources -> Add Korean & Japanese
        1. open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
        2. Text Input -> Input Sources -> Edit... -> `+` -> Korean, Japanese
        3. (The setting lives in `com.apple.HIToolbox`, but writing it by hand does not register the input sources reliably.)
    2. Auto: don't use "smart quotes and dashes" (GUI: Edit -> Substitutions -> Smart Quotes / Smart Dashes)
        1. defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
        2. defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled  -bool false
5. Mouse (Auto; needs logout)
    1. Manual way: open "x-apple.systempreferences:com.apple.Mouse-Settings.extension" -> Secondary Click on the right side
    2. defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string TwoButton
    3. defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string TwoButton
6. Trackpad (Auto; needs logout)
    1. Manual way:
        1. open "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"
        2. open "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?PointerControl"
        3. TrackPad -> Use trackpad for dragging -> With Drag Lock
    2. defaults write com.apple.AppleMultitouchTrackpad Dragging -bool true
    3. defaults write com.apple.AppleMultitouchTrackpad DragLock -bool true
    4. The same two keys for `com.apple.driver.AppleBluetoothMultitouch.trackpad` (external Magic Trackpad)
7. Finder
    1. Auto: list view as the default
        * defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
        * killall Finder
        * defaults read com.apple.finder FXPreferredViewStyle
    2. [No Auto] A folder you already opened keeps its own view. Open it -> Cmd-2 -> Cmd-J (Show View Options) -> "Always open in list view" -> "Use as Defaults".
8. TextEdit (Auto): no auto substitution, plain text by default
    1. defaults write com.apple.TextEdit SmartQuotes -bool false
    2. defaults write com.apple.TextEdit SmartDashes -bool false
    3. defaults write com.apple.TextEdit SmartLinks -bool false
    4. defaults write com.apple.TextEdit TextReplacement -bool false
    5. defaults write com.apple.TextEdit RichText -int 0
9. Homebrew (Auto)
    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ```
    * `brew` commands need no sudo, but this installer creates `/opt/homebrew` as an administrator and asks for the password.
    * PATH for later shells is set by `setup`'s zprofile, so the scripts do not edit a profile file.

Only brew is installed here. The other apps (mas, Bear, VSCode, Claude, Python 3.14, ...) are installed with brew afterwards, all at once.

---

# Part 3 - `3_sudorun.sh` (needs sudo)

Run as yourself, not with `sudo`. The password is asked only when a step has something to change.
Every new step that needs sudo goes here.

1. Remote Login (SSH), so other computers can ssh into this Mac (Auto if the terminal has Full Disk Access)
    1. Manual way: open "x-apple.systempreferences:com.apple.Sharing-Settings.extension" -> turn on Remote Login
    2. Command:
        ```
        sudo systemsetup -setremotelogin on
        nc -z localhost 22 && echo "port 22 is open"
        ```
    3. [No Auto] If the command prints `requires Full Disk Access privileges`, the script reports this step as `No Auto`.
       Either do the manual way above, or allow the terminal app in System Settings -> Privacy & Security -> Full Disk Access and re-run.
    4. This only opens the door. To log in without a password, put the other computer's public key in `~/.ssh/authorized_keys` on this Mac.
2. Who may log in over SSH (Auto): the account running the script must be allowed
    1. Manual way: open "x-apple.systempreferences:com.apple.Sharing-Settings.extension" -> Remote Login `(i)` -> "Allow access for":
       **All users**, or **Only these users** with your account in the list.
       An account that is not in the list is disconnected right after the password (`Connection closed by ... port 22`).
    2. How it is stored: "Only these users" is the group `com.apple.access_ssh`. No such group means all users are allowed.
        ```
        dseditgroup -o checkmember -m "$USER" com.apple.access_ssh    # "yes ..." if allowed
        sudo dseditgroup -o edit -a "$USER" -t user com.apple.access_ssh
        ```
    3. The script does nothing if the group does not exist or already contains you. If the list exists without you, it adds you.
       It never opens SSH to everybody. To allow all users yourself: `sudo dseditgroup -o delete com.apple.access_ssh`.
    4. A school-managed Mac may still refuse password logins by policy. Then use the manual way, or ask IT.

---

# Part 4 - `4_email.sh`

How much can be automated: almost nothing. Adding an account needs a password plus a second factor or a browser login, and macOS has no supported command for it. A configuration profile does not help either: the Google account payload is iOS-only, and macOS shows it as "iOS-only settings" and does not create the accounts.
So the script checks what it can (step 1), opens Internet Accounts with your Google address list (step 3) and lists the rest as `[No Auto]`. It changes nothing and is safe to re-run.

1. Apple Account (Auto check only; sign-in is [No Auto])
    1. The script reads `defaults read MobileMeAccounts Accounts` and prints the signed-in account. `OK` if found, otherwise `No Auto`.
    2. Manual way: open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings?iCloud" -> sign in -> iCloud -> turn on Mail
    3. If you already did Part 2 step 1, this step is `OK`.
2. [No Auto] Microsoft (NKU school account)
    1. School login (SSO + MFA) must be done by you.
    2. open "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension" -> Add Account -> Microsoft Exchange -> sign in with the NKU account
    3. Choose Mail (and Calendars, Contacts if wanted). A school-managed Mac may have its own policy.
3. [No Auto] Google accounts (several)
    1. Optional: put one e-mail per line in `accounts.txt` (next to the script; `#` lines are ignored).
    2. The script prints the addresses and opens Internet Accounts for you.
    3. By hand, once for each address: open "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension" -> Add Account -> Google -> sign in in the browser sheet (password + 2-step) -> choose Mail (and others if wanted).
    4. Each account needs its own browser login (OAuth), so the status is always `No Auto`.

The Internet Accounts link depends on the macOS version: the script uses `com.apple.Internet-Accounts-Settings.extension` on macOS 13+ and `com.apple.preferences.internetaccounts` before that.
A school-managed Mac (NKU) may hide or block the pane. Then open Mail -> menu Mail -> Add Account... instead; if that is blocked too, ask IT.
