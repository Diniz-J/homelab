#!/usr/bin/env bash
# Pull the homelab-backup bucket from the in-cluster MinIO to a local
# directory, so there's a cold copy off the cluster.
#
# Assumes:
#   - kubectl context "k3d-homelab" is reachable
#   - rclone is installed
#   - A port-forward to minio is running on $MINIO_HOST (see below)
#
# Defaults can be overridden with env vars:
#   KUBE_CONTEXT    kubectl context          (default: k3d-homelab)
#   KUBE_NAMESPACE  minio namespace          (default: minio)
#   MINIO_HOST      minio host:port          (default: localhost:9000)
#   MINIO_USER      access key id            (default: minioadmin)
#   MINIO_PASS      secret access key        (default: minioadmin123)
#   LOCAL_DIR       destination directory    (default: $HOME/homelab-backups)
#   FORWARD         "true" to open port-forward here, "false" to assume
#                   one is already running elsewhere (default: true)

set -euo pipefail

KUBE_CONTEXT="${KUBE_CONTEXT:-k3d-homelab}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-minio}"
MINIO_HOST="${MINIO_HOST:-localhost:9000}"
MINIO_USER="${MINIO_USER:-minioadmin}"
MINIO_PASS="${MINIO_PASS:-minioadmin123}"
LOCAL_DIR="${LOCAL_DIR:-$HOME/homelab-backups}"
FORWARD="${FORWARD:-true}"

mkdir -p "$LOCAL_DIR"

if ! command -v rclone >/dev/null; then
  echo "rclone not found. Install it from https://rclone.org/downloads/." >&2
  exit 1
fi

cleanup_pid=""
cleanup() {
  if [[ -n "$cleanup_pid" ]]; then
    kill "$cleanup_pid" 2>/dev/null || true
    wait "$cleanup_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [[ "$FORWARD" == "true" ]]; then
  echo "Opening port-forward to minio on $MINIO_HOST..."
  kubectl --context "$KUBE_CONTEXT" -n "$KUBE_NAMESPACE" \
    port-forward svc/minio "${MINIO_HOST##*:}:9000" >/dev/null 2>&1 &
  cleanup_pid=$!

  # Wait up to 10s for the forward to be ready.
  for _ in {1..10}; do
    if (echo > "/dev/tcp/${MINIO_HOST%:*}/${MINIO_HOST##*:}") 2>/dev/null; then
      break
    fi
    sleep 1
  done
fi

export RCLONE_CONFIG_MINIO_TYPE=s3
export RCLONE_CONFIG_MINIO_PROVIDER=Minio
export RCLONE_CONFIG_MINIO_ACCESS_KEY_ID="$MINIO_USER"
export RCLONE_CONFIG_MINIO_SECRET_ACCESS_KEY="$MINIO_PASS"
export RCLONE_CONFIG_MINIO_ENDPOINT="http://$MINIO_HOST"

echo "Syncing minio:homelab-backup -> $LOCAL_DIR"
rclone sync minio:homelab-backup "$LOCAL_DIR" --progress

echo "Done. Local copy in $LOCAL_DIR"
ls -lh "$LOCAL_DIR" | tail -n +2
