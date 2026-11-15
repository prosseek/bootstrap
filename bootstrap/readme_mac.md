# First Install Mac

Make sure you have the correct "Git Classical Keys"

```
scp -p ~/github/prosseek/setup/_lib/git/tokens/tokens.txt.zip smcho@hp.local:github/prosseek/setup/_lib/git/tokens/
```

## 0 zsh/github/ssh & prosseek/bin

1. bootstrap => prosseek/setup
2. config/zsh/run.sh => zsh
3. shell: `setup_gs` => ~/github/prosseek/setup/conf/_setup_gs.txt
    1. config/ssh/run.sh
        1. automatically run _lib/git/tokens
        2. Update this key if necessary, always zip it
        3. Run other run_*.sh for automatic ssh access
    2. config/git/run.sh
4. gitclone prosseek bin

## 1_first_step

~/github/prosseek/setup/bootstrap/1_first_step

1. 1_hostname.sh to set hostname
2. 2_run to set configuration manually or automatically
  - some are automatic
  - some are manual => follow the instructions
3. 3_sudorun.sh for sudo run required actions
  - ssh
4. 4_email.sh to setup email accounts
  - apple is automatic
  - school (microsoft)
  - 6 google accounts

## 2_install_apps

~/github/prosseek/setup/bootstrap/2_install_apps/mac

1. Install essentail brew & mas
    1. brew => install essentials
        1. ~/github/prosseek/setup/bootstrap/2_install_apps/mac/brew/run.sh
    2. mas => install essentials
        1. ~/github/prosseek/setup/bootstrap/2_install_apps/mac/mas/run.sh

2. Post Installation
    1. shell: `setup_unix` => ~/github/prosseek/setup/conf/_setup_unix.txt

