#!/usr/bin/env bash
#
# Local deploy: rsync the tree to the server, optionally build and restart
# the container there, mirroring .github/workflows/deploy.yml.
#
#   ./deploy.sh              rsync the tree to DEPLOY_PATH
#   ./deploy.sh --build      ...then build and restart the container
#   ./deploy.sh --dry-run    show what would change, touch nothing
#   ./deploy.sh --prune      also delete files removed locally
#
# Build also ensures the ufw rule that lets Caddy reach APP_PORT. That needs
# passwordless sudo for ufw on the deploy user.
#
# Defaults match the old scp command; override any of them via the environment:
#   SSH_KEY, SSH_PORT, DEPLOY_USER, DEPLOY_HOST, DEPLOY_PATH, APP_PORT

set -eo pipefail

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_mdd_linode}"
SSH_PORT="${SSH_PORT:-22}"
DEPLOY_USER="${DEPLOY_USER:-preview}"
DEPLOY_HOST="${DEPLOY_HOST:-mdd-production}"
DEPLOY_PATH="${DEPLOY_PATH:-/home/preview/workbench/php-stub}"
APP_PORT="${APP_PORT:-8080}"

dry_run=0
prune=0
build=0

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [--build] [--dry-run] [--prune]

      --build     Build the image on the server and restart the container
                  (docker compose up -d --build --remove-orphans, then prune).
  -n, --dry-run   Show what rsync would change without touching the server.
      --prune     Delete server files that no longer exist locally.
  -h, --help      Show this help.

Environment overrides: SSH_KEY, SSH_PORT, DEPLOY_USER, DEPLOY_HOST, DEPLOY_PATH,
APP_PORT.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --build) build=1 ;;
    -n|--dry-run) dry_run=1 ;;
    --prune) prune=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ ! -r "$SSH_KEY" ]; then
  echo "ssh key not readable: $SSH_KEY" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is not installed" >&2
  exit 1
fi

rsync_opts=(-a --human-readable --itemize-changes)
if [ "$dry_run" -eq 1 ]; then rsync_opts+=(--dry-run); fi
if [ "$prune" -eq 1 ]; then rsync_opts+=(--delete); fi

# The trailing slash on ./ copies the contents of this directory into
# DEPLOY_PATH, like `scp -r *` does, instead of nesting the folder itself.
# Everything is synced except .git, .github and Finder metadata.
rsync "${rsync_opts[@]}" \
  -e "ssh -i $SSH_KEY -p $SSH_PORT" \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='.DS_Store' \
  ./ "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH"

echo "synced to $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH"

if [ "$build" -eq 0 ]; then
  exit 0
fi

if [ "$dry_run" -eq 1 ]; then
  echo "dry run: skipping remote build" >&2
  exit 0
fi

ssh -i "$SSH_KEY" -p "$SSH_PORT" "$DEPLOY_USER@$DEPLOY_HOST" \
  "DEPLOY_PATH='$DEPLOY_PATH' APP_PORT='$APP_PORT' bash -s" <<'REMOTE'
set -eu
cd "$DEPLOY_PATH"
APP_PORT="${APP_PORT:-8080}"

# Fail early if the copy is incomplete (e.g. etc/ was never uploaded)
# instead of dying inside the build with a checksum error.
for f in Dockerfile docker-compose.yml index.php etc/nginx.conf etc/supervisord.conf; do
  if [ ! -f "$f" ]; then
    echo "missing build input: $DEPLOY_PATH/$f" >&2
    exit 1
  fi
done

# Build locally from the synced source; no registry involved.
docker compose up -d --build --remove-orphans

# Let Caddy (on the host or in another container) reach the published port
# across the Docker bridge. Idempotent: ufw reports the rule exists and exits 0.
if command -v ufw >/dev/null 2>&1; then
  sudo -n ufw allow from 172.16.0.0/12 to any port "$APP_PORT" proto tcp \
    comment 'Allow Caddy to reach rootless preview app' ||
    { echo "ufw rule failed: the deploy user needs passwordless sudo for ufw" >&2; exit 1; }
else
  echo "ufw not found; skipping firewall rule" >&2
fi

# Drop the image the rebuild replaced; keep the build cache for next time.
docker image prune -af

docker compose ps
REMOTE
