# Mac - First Step

Run the scripts in this order. Each part below matches one script, and the step numbers
are the same as the ones the script prints (`[1] OK ...`) and lists in its summary table.

```
bash 1_hostname.sh   # Part 1: computer name (needs sudo)
                     # Parts 2 and 3 moved to ~/github/prosseek/setup_mac/_Mac (see below)
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

# Part 2 - `2_email.sh`

How much can be automated: almost nothing. Adding an account needs a password plus a second factor or a browser login, and macOS has no supported command for it. A configuration profile does not help either: the Google account payload is iOS-only, and macOS shows it as "iOS-only settings" and does not create the accounts.
So the script checks what it can (step 1), opens Internet Accounts with your Google address list (step 3) and lists the rest as `[No Auto]`. It changes nothing and is safe to re-run.

1. Apple Account (Auto check only; sign-in is [No Auto])
    1. The script reads `defaults read MobileMeAccounts Accounts` and prints the signed-in account. `OK` if found, otherwise `No Auto`.
    2. Manual way: open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings?iCloud" -> sign in -> iCloud -> turn on Mail
    3. If you already signed in to the Apple Account (`setup_mac/_Mac/mac_manual_setup/3_manual.sh.md`, step 1), this step is `OK`.
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

---

## Parts 2 and 3 moved to `setup_mac/_Mac`

`2_run.sh` (keyboard, mouse, trackpad, Finder, TextEdit) and `3_sudorun.sh` (Remote Login / SSH)
are now `1_run.sh` and `2_sudorun.sh` in `~/github/prosseek/setup_mac/_Mac/mac_setup`, with their documentation
(`1_run.sh.md`, `2_sudorun.sh.md` there, in Korean). The steps that cannot be automated (Apple Account,
Touch ID, input sources ...) are in `3_manual.sh` there: it opens the System Settings panes one after another.
`_Mac/runall.sh` is the only file outside that folder; it runs `mac_setup/run.sh` (and ignores folders without a `run.sh`, logging them as `<name>.ignore.log`).
They run together with the rest of `setup_mac`:

```
cd ~/github/prosseek/setup_mac
bash runall.sh            # runs _Mac/runall.sh (mac_setup/run.sh, Dockutil) and every other app folder
bash _Mac/runall.sh       # only the Mac settings (3_manual.sh is run by hand)
```

Homebrew was step 9 of the old `2_run.sh`. It is now installed by `2_install_apps/mac/brew/run.sh`
when it is missing, so that script no longer needs `2_run.sh` first.

Order on a new Mac: `1_hostname.sh` -> `2_install_apps` (brew, mas) -> `setup_mac/runall.sh` -> `4_email.sh`.

