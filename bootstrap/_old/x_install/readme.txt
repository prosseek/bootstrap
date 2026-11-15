## zsh -> ssh -> git Configuration

1. Run conf/zsh/run.sh to install zsh configuration files.
2. Run conf/ssh/run.sh to install ssh related files (github access).
3. Run `python3 $HOME/github/prosseek/setup/_lib/git/key_tools/3_github_remote_update.py`
   (On a fresh machine with no HTTPS-cloned repos yet, this may report 0 converted -- that's normal.)
4. Run conf/git/run.sh to install git related files.
---

## Install tools 

### Mac: through brew 

All the apps are installed using `brew bundle`

5-1. Run ~/github/prosseek/setup/bootstrap/_setup/mac/first_setup_mac.sh

---

## Github Sync

6. More GitHub sync
- gitclone prosseek bin
- gitclone mss2ms mss2ms

Next step: install Mac applications & configure mac