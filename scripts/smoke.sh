#!/usr/bin/env bash
# Quick check that the lab is actually serving what dev-up printed.
#
# Three HTTP checks against the ingress hostnames, plus a pass over
# every ArgoCD Application making sure it's Synced + Healthy. Exits
# non-zero if anything is off.
#
# Env-var overrides:
#   HOST_SUFFIX     ingress host suffix       (default: homelab.localhost)
#   HTTPS_PORT      host port for :443        (default: 8443)
#   KUBE_CONTEXT    kubectl context           (default: k3d-homelab)
#   CURL_FLAGS      extra curl flags          (default: -k --connect-timeout 5 --max-time 10)

set -euo pipefail

HOST_SUFFIX="${HOST_SUFFIX:-homelab.localhost}"
HTTPS_PORT="${HTTPS_PORT:-8443}"
KUBE_CONTEXT="${KUBE_CONTEXT:-k3d-homelab}"
CURL_FLAGS="${CURL_FLAGS:--k --connect-timeout 5 --max-time 10}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
pass() { printf '  \033[32mOK\033[0m   %s\n' "$*"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; }

rc=0

check_http() {
  local name="$1" url="$2" want="${3:-200}"
  local got
  got=$(curl -s -o /dev/null -w '%{http_code}' $CURL_FLAGS "$url" || echo "---")
  if [[ "$got" == "$want" ]]; then
    pass "$(printf '%-28s %s' "$name" "$url")"
  else
    fail "$(printf '%-28s %s (got %s, want %s)' "$name" "$url" "$got" "$want")"
    rc=1
  fi
}

bold "Platform endpoints"
check_http "go-sample /healthz" \
  "https://go-sample.${HOST_SUFFIX}:${HTTPS_PORT}/healthz"
check_http "grafana /api/health" \
  "https://grafana.${HOST_SUFFIX}:${HTTPS_PORT}/api/health"
check_http "minio /minio/health/live" \
  "https://minio.${HOST_SUFFIX}:${HTTPS_PORT}/minio/health/live"

bold "ArgoCD applications"
if ! kubectl --context "$KUBE_CONTEXT" -n argocd \
    get applications -o json >/tmp/apps.json 2>/dev/null; then
  fail "kubectl -n argocd get applications failed"
  exit 1
fi

# jq is nicer; fall back to a tolerant awk pipeline if it isn't there.
if command -v jq >/dev/null; then
  mapfile -t rows < <(jq -r '
    .items[] | [.metadata.name, .status.sync.status // "?", .status.health.status // "?"] | @tsv
  ' /tmp/apps.json)
else
  mapfile -t rows < <(python3 - <<'PY' </tmp/apps.json
import json, sys
for app in json.load(sys.stdin).get("items", []):
    name = app["metadata"]["name"]
    sync = app.get("status", {}).get("sync", {}).get("status", "?")
    health = app.get("status", {}).get("health", {}).get("status", "?")
    print(f"{name}\t{sync}\t{health}")
PY
)
fi

for row in "${rows[@]}"; do
  IFS=$'\t' read -r name sync health <<<"$row"
  if [[ "$sync" == "Synced" && "$health" == "Healthy" ]]; then
    pass "$(printf '%-28s sync=%s health=%s' "$name" "$sync" "$health")"
  else
    fail "$(printf '%-28s sync=%s health=%s' "$name" "$sync" "$health")"
    rc=1
  fi
done

rm -f /tmp/apps.json
exit "$rc"
