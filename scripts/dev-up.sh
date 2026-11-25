#!/usr/bin/env bash
# One-shot developer path from a fresh clone to a lab that answers:
#
#   terraform apply  ->  ArgoCD bootstrap  ->  root Application sync
#
# Env-var overrides:
#   KUBE_CONTEXT     kubectl context          (default: k3d-homelab)
#   TF_DIR           terraform stack path     (default: terraform)
#   ARGOCD_NS        ArgoCD namespace         (default: argocd)
#   SYNC_TIMEOUT_S   seconds to wait on root  (default: 600)

set -euo pipefail

KUBE_CONTEXT="${KUBE_CONTEXT:-k3d-homelab}"
TF_DIR="${TF_DIR:-terraform}"
ARGOCD_NS="${ARGOCD_NS:-argocd}"
SYNC_TIMEOUT_S="${SYNC_TIMEOUT_S:-600}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }

for cmd in terraform kubectl kustomize k3d; do
  if ! command -v "$cmd" >/dev/null; then
    echo "missing prerequisite: $cmd" >&2
    exit 1
  fi
done

bold "[1/4] terraform apply"
terraform -chdir="$TF_DIR" init -upgrade
terraform -chdir="$TF_DIR" apply -auto-approve

bold "[2/4] bootstrap ArgoCD"
kustomize build k8s/bootstrap/argocd/ \
  | kubectl --context "$KUBE_CONTEXT" apply -f -

kubectl --context "$KUBE_CONTEXT" -n "$ARGOCD_NS" \
  wait --for=condition=Available deploy/argocd-server --timeout=5m
kubectl --context "$KUBE_CONTEXT" -n "$ARGOCD_NS" \
  wait --for=condition=Available deploy/argocd-repo-server --timeout=5m

bold "[3/4] root Application"
kubectl --context "$KUBE_CONTEXT" apply -f k8s/apps/root.yaml

deadline=$(( $(date +%s) + SYNC_TIMEOUT_S ))
while :; do
  sync=$(kubectl --context "$KUBE_CONTEXT" -n "$ARGOCD_NS" \
    get application root -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  health=$(kubectl --context "$KUBE_CONTEXT" -n "$ARGOCD_NS" \
    get application root -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  printf '  root sync=%s health=%s\n' "${sync:-?}" "${health:-?}"
  if [[ "$sync" == "Synced" ]]; then
    break
  fi
  if (( $(date +%s) > deadline )); then
    echo "timeout waiting for root to sync" >&2
    exit 1
  fi
  sleep 10
done

bold "[4/4] where to look next"
cat <<EOF

  ArgoCD UI    kubectl --context $KUBE_CONTEXT -n $ARGOCD_NS \\
                 port-forward svc/argocd-server 8081:443
               https://localhost:8081
               admin / \$(kubectl --context $KUBE_CONTEXT -n $ARGOCD_NS \\
                 get secret argocd-initial-admin-secret \\
                 -o jsonpath='{.data.password}' | base64 -d)

  Grafana      https://grafana.homelab.localhost:8443  (admin / admin)
  go-sample    https://go-sample.homelab.localhost:8443/healthz
  MinIO        https://minio.homelab.localhost:8443

  Trust the homelab-ca first: see docs/trust-store.md.

EOF
