# First Install Mac

Make sure you have the correct "Git Classical Keys"

```
scp -p ~/github/prosseek/setup/_lib/git_token/tokens.txt.zip smcho@hp.local:github/prosseek/setup/_lib/git_token/
```

## 0 zsh/github/ssh & prosseek/bin

1. bootstrap => prosseek/setup
2. config/zsh/run.sh => zsh
3. shell: `setup_gs` => ~/github/prosseek/setup/conf/_setup_gs.txt
    1. config/ssh/run.sh
        1. automatically run _lib/git_token
        2. Update this key if necessary, always zip it
        3. Run other run_*.sh for automatic ssh access
    2. config/git/run.sh
4. gitclone prosseek bin

## 1_first_step

~/github/prosseek/bootstrap/bootstrap/1_first_step/mac

1. 1_hostname.sh to set hostname

(2_run.sh and 3_sudorun.sh moved to ~/github/prosseek/setup_mac/_Mac/setup as 1_run.sh and 2_sudorun.sh, see "3 setup_mac" below.)

## 2_install_apps

~/github/prosseek/bootstrap/bootstrap/2_install_apps/mac

1. Install essentail brew & mas
    1. brew => installs Homebrew if it is missing, then the essentials
        1. ~/github/prosseek/bootstrap/bootstrap/2_install_apps/mac/brew/run.sh
    2. mas => install essentials
        1. ~/github/prosseek/bootstrap/bootstrap/2_install_apps/mac/mas/run.sh

2. Post Installation
    1. shell: `setup_unix` => ~/github/prosseek/setup/conf/_setup_unix.txt

## 3 setup_mac

~/github/prosseek/setup_mac

1. `bash runall.sh` runs the run.sh of every app folder, including `_Mac/run.sh`
    1. _Mac/setup/1_run.sh => keyboard, mouse, trackpad, Finder, TextEdit (automatic)
    2. _Mac/setup/2_sudorun.sh => sudo run required actions (ssh)
    3. _Mac/setup/3_manual.sh => opens the System Settings panes for the manual steps (press the back button to go on)
    4. See ~/github/prosseek/setup_mac/_Mac/setup/readme.md, 1_run.sh.md, 2_sudorun.sh.md, 3_manual.sh.md

## 4_email

1. ~/github/prosseek/bootstrap/bootstrap/1_first_step/mac/4_email.sh to setup email accounts
  - apple is automatic
  - school (microsoft)
  - 6 google accounts

