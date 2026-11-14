# bootstrap

Clone the private `prosseek/setup` repo on a brand-new machine.

## Usage

Requires `git`. The bootstrap repo is public; `setup` is private.

```bash
git clone https://github.com/prosseek/bootstrap.git
cd bootstrap
GH_TOKEN=ghp_xxxxxxxx bash bootstrap.sh
```

`GH_TOKEN` is a GitHub token with the `admin:public_key` scope
([create one](https://github.com/settings/tokens/new?scopes=admin:public_key&description=bootstrap)).
It is used only to register this machine's SSH key. Never commit it.
Delete the token afterwards.

## What it does

1. `ensure_key`: create `~/.ssh/id_ed25519_prosseek` if missing.
2. `ensure_github_access`: if GitHub rejects the key, register it
   (replacing old keys with the same machine name) using `GH_TOKEN`.
3. `clone_setup`: clone (or pull) to `~/github/prosseek/setup`,
   and pin the key to that repo so later `pull`/`push` need no token.

The key is titled with the hostname. Set `MACHINE_NAME=<name>` to override.

## Re-running

Safe to re-run. To force a new key, remove only that key:
`rm ~/.ssh/id_ed25519_prosseek*`. Do not delete `~/.ssh`.
