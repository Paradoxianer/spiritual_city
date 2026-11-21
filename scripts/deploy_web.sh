#!/usr/bin/env bash
# Builds the web version and uploads it to spiritual-city.org (hosting.de
# webspace, SSH on port 2244). No credentials live here: user and server
# come from the environment, the login from an SSH key registered for the
# user in the hosting.de panel (SSH_KEY) – or SSH asks for the password.
#
#   SFTP_USER=<user> SFTP_HOST=<server> [SSH_KEY=~/.ssh/<key>] scripts/deploy_web.sh
set -euo pipefail

: "${SFTP_USER:?set SFTP_USER (FTP/SSH user of the webspace)}"
: "${SFTP_HOST:?set SFTP_HOST (server name of the webspace)}"
SFTP_PORT="${SFTP_PORT:-2244}"
TARGET="${TARGET:-html/spiritual-city.org}"

SSH="ssh -p $SFTP_PORT"
if [ -n "${SSH_KEY:-}" ]; then
  SSH="$SSH -o IdentityAgent=none -o IdentitiesOnly=yes -i $SSH_KEY"
fi

cd "$(dirname "$0")/.."
flutter build web --release --base-href=/
# --delete only inside the game's own folder.
rsync -az --delete -e "$SSH" build/web/ "$SFTP_USER@$SFTP_HOST:$TARGET/"
echo "✓ https://spiritual-city.org"
