# Mac - First Step

Run the scripts in this order. Each part below matches one script, and the step numbers
are the same as the ones the script prints (`[1] OK ...`) and lists in its summary table.

```
bash 1_hostname.sh   # Part 1: computer name (needs sudo)
                     # Parts 2 and 3 moved to ~/github/prosseek/setup_mac/_Mac (see below)
bash 2_email.sh      # Part 2: iCloud / Apple Account (check only)
                     # Microsoft/NKU and Google mail: ~/github/prosseek/setup_mac/_ManualSetup/_email_setup/email.sh
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

# Part 2 - `2_email.sh` (iCloud only)

This script only deals with the Apple Account (iCloud). The other mail accounts (Microsoft/NKU and Google) are in
`~/github/prosseek/setup_mac/_ManualSetup/_email_setup/` (`email.sh`, with `email.sh.md` in Korean).

How much can be automated: almost nothing. Signing in to the Apple Account needs a password plus a second factor, and macOS has no supported command for it.
So the script only checks what it can (step 1) and lists the rest as `[No Auto]`. It changes nothing and is safe to re-run.

1. Apple Account (Auto check only; sign-in is [No Auto])
    1. The script reads `defaults read MobileMeAccounts Accounts` and prints the signed-in account. `OK` if found, otherwise `No Auto`.
    2. Manual way: open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings?iCloud" -> sign in -> iCloud -> turn on Mail
    3. If you already signed in to the Apple Account (`setup_mac/_ManualSetup/_mac_manual_setup/3_manual.sh.md`, step 1), this step is `OK`.

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

Order on a new Mac: `1_hostname.sh` -> `2_install_apps` (brew, mas) -> `setup_mac/runall.sh` -> `2_email.sh` (iCloud) -> `setup_mac/_ManualSetup/_email_setup/email.sh` (NKU + Gmail).

