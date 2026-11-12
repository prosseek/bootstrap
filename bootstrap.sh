#!/usr/bin/env bash
#
# bootstrap.sh - clone the private prosseek/setup repo on a brand-new machine.
#
# Usage:
#   GH_TOKEN=ghp_xxxxxxxx bash bootstrap.sh
#
# GH_TOKEN: prosseek's GitHub token with the "admin:public_key" scope.
# It is only used to register this machine's SSH key on GitHub.
set -euo pipefail

ACCOUNT="prosseek"
KEY="$HOME/.ssh/id_ed25519_prosseek"
REPO_URL="git@github.com:$ACCOUNT/setup.git"
TARGET="$HOME/github/$ACCOUNT/setup"
API="https://api.github.com/user/keys"
TOKEN_URL="https://github.com/settings/tokens/new?scopes=admin:public_key&description=bootstrap"

SSH_CMD="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
export GIT_SSH_COMMAND="$SSH_CMD"

log() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# The key name on GitHub is derived from the hostname (unique per machine)
machine_name() { hostname -s; }

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
    git ls-remote "$REPO_URL" > /dev/null 2>&1
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

# Delete keys on GitHub that have this machine's name (left over from before a reformat)
delete_old_keys() {
    local name ids id
    name="$(machine_name)"
    ids="$(github_api "$API?per_page=100" \
        | awk -v t="$name" '
            /"id":/ { id = $2; gsub(/[^0-9]/, "", id) }
            $1 == "\"title\":" && $2 == ("\"" t "\",") { print id }')" \
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
    github_api -X POST "$API" \
        -d "{\"title\":\"$name\",\"key\":\"$(cat "$KEY.pub")\"}" > /dev/null \
        || die "Key registration failed (is this public key already used by another account?)."
}

ensure_github_access() {
    if can_access_repo; then
        log "GitHub already accepts this key"
        return
    fi
    require_token
    delete_old_keys
    register_key
    can_access_repo || die "Still cannot access $REPO_URL. Wait a few seconds and run again."
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
