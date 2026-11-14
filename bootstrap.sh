#!/usr/bin/env bash
#
# bootstrap.sh - clone the private prosseek/setup repo on a brand-new machine.
#
# Usage:
#   GH_TOKEN=ghp_xxxxxxxx bash bootstrap.sh
#
# GH_TOKEN: prosseek's GitHub token with the "admin:public_key" scope.
# It is only used to register this machine's SSH key on GitHub.
#
# Notes:
#   - Meant for a brand-new machine, but safe to re-run: an existing key is
#     reused, and GitHub keys with this machine's name or this exact public key
#     are deleted and registered again.
#   - Do NOT delete ~/.ssh to retry. It would also remove authorized_keys (SSH
#     login to a server), the other accounts' keys and ~/.ssh/config.
#     To force a new key, remove only this one: rm ~/.ssh/id_ed25519_prosseek*
#   - The user's git config is ignored (GIT_CONFIG_GLOBAL below), so url.insteadOf
#     rules such as git@github.com:prosseek/ -> git@prosseek: (an ssh host alias
#     that may not exist yet) cannot break the clone.
#   - To test the fresh-machine condition on a used machine:
#       mv ~/.config/git ~/.config/git.bak   # restore it afterwards
set -euo pipefail

ACCOUNT="prosseek"
KEY="$HOME/.ssh/id_ed25519_$ACCOUNT"
REPO_URL="git@github.com:$ACCOUNT/setup.git"
TARGET="$HOME/github/$ACCOUNT/setup"
API="https://api.github.com/user/keys"
TOKEN_URL="https://github.com/settings/tokens/new?scopes=admin:public_key&description=bootstrap"

SSH_CMD="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
export GIT_SSH_COMMAND="$SSH_CMD"
# Ignore the user's/system git config (e.g. url.insteadOf rewrites to an ssh host alias
# like "prosseek") so bootstrap always talks to github.com with its own key.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

log() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# The key name on GitHub is derived from the hostname (unique per machine)
machine_name() {
    local n="${MACHINE_NAME:-$(uname -n | cut -d. -f1)}"
    [ -n "$n" ] && [ "$n" != "localhost" ] || { echo "Set MACHINE_NAME=<name>" >&2; exit 1; }
    echo "$n"
}

require_token() {
    [ -n "${GH_TOKEN:-}" ] || die "GH_TOKEN is empty.
  1. Create a token (scope: admin:public_key): $TOKEN_URL
  2. Run: GH_TOKEN=ghp_xxxxxxxx bash $0"
}

github_api() {
    curl -fsS \
        -H "Authorization: Bearer $GH_TOKEN" \
        -H "Accept: application/vnd.github+json" "$@"
}

can_access_repo() {
    command -v git > /dev/null || die "git is not installed."
    git ls-remote "$REPO_URL" > /dev/null 2> "${TMPDIR:-/tmp}/bootstrap_ls_remote.err"
}

show_access_error() {
    echo "--- git ls-remote error ---" >&2
    cat "${TMPDIR:-/tmp}/bootstrap_ls_remote.err" >&2 || true
}

ensure_key() {
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [ -f "$KEY" ]; then
        log "SSH key exists: $KEY"
        return
    fi
    log "Creating SSH key: $KEY"
    ssh-keygen -q -t ed25519 -N "" -C "$(machine_name)" -f "$KEY"
}

# Delete keys on GitHub that either have this machine's name (left over from
# before a reformat) or contain this exact public key (registered under another title).
# Otherwise GitHub rejects the registration with 422 "key is already in use".
delete_old_keys() {
    local name blob ids id
    name="$(machine_name)"
    blob="$(awk '{ print $2 }' "$KEY.pub")"
    ids="$(github_api "$API?per_page=100" \
        | awk -v t="$name" -v b="$blob" '
            /"id":/ { id = $2; gsub(/[^0-9]/, "", id) }
            $1 == "\"key\":" && index($0, b) { print id }
            $1 == "\"title\":" && $2 == ("\"" t "\",") { print id }' \
        | sort -u)" \
        || die "GitHub API call failed. Check the token and its scope (admin:public_key)."
    for id in $ids; do
        log "Deleting old GitHub key #$id ($name)"
        github_api -X DELETE "$API/$id" > /dev/null
    done
}

register_key() {
    local name
    name="$(machine_name)"
    log "Registering key on GitHub as '$name'"
    local resp code
    resp="$(curl -sS -w '\n%{http_code}' -X POST "$API" \
        -H "Authorization: Bearer $GH_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -d "{\"title\":\"$name\",\"key\":\"$(cat "$KEY.pub")\"}")"
    code="${resp##*$'\n'}"
    if [ "$code" != "201" ]; then
        echo "${resp%$'\n'*}" >&2
        die "Key registration failed (HTTP $code). If 'key is already in use': the key is on another GitHub account or is a repo deploy key. Remove it there, or delete $KEY* and run again to create a new key."
    fi
}

ensure_github_access() {
    if can_access_repo; then
        log "GitHub already accepts this key"
        return
    fi
    require_token
    delete_old_keys
    register_key
    # A newly registered key can take a few seconds to become active on GitHub
    local i
    for i in 1 2 3 4 5 6; do
        can_access_repo && return
        log "Waiting for GitHub to activate the key ($i/6)"
        sleep 3
    done
    show_access_error
    die "Still cannot access $REPO_URL. Check: $SSH_CMD -T git@github.com"
}

clone_setup() {
    mkdir -p "$(dirname "$TARGET")"
    if [ -d "$TARGET/.git" ]; then
        log "Updating $TARGET"
        git -C "$TARGET" pull
    else
        log "Cloning $REPO_URL"
        git clone "$REPO_URL" "$TARGET"
    fi
    # Pin this key to the repo so later pull/push work without any token
    git -C "$TARGET" config core.sshCommand "$SSH_CMD"
}

main() {
    ensure_key
    ensure_github_access
    clone_setup
    log "Done: $TARGET"
}

main "$@"
