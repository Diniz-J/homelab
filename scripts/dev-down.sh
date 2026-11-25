#!/usr/bin/env bash
# Tear everything the dev-up script brings up back down. Terraform
# destroy clears the k3d cluster, the Docker network and the local
# registry; anything k3d created survives that goes in step 2.
#
# Env-var overrides:
#   TF_DIR          terraform stack path   (default: terraform)
#   PRUNE_VOLUMES   also prune unused Docker volumes  (default: false)

set -euo pipefail

TF_DIR="${TF_DIR:-terraform}"
PRUNE_VOLUMES="${PRUNE_VOLUMES:-false}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }

bold "[1/2] terraform destroy"
terraform -chdir="$TF_DIR" destroy -auto-approve || true

bold "[2/2] mop-up"
# Catch any k3d artefact that outlived terraform (an early-apply crash
# before the registry/network was tracked in state, say).
if command -v k3d >/dev/null; then
  for cluster in $(k3d cluster list -o json 2>/dev/null \
      | awk -F'"' '/"name":/ && /homelab/ {print $4}'); do
    k3d cluster delete "$cluster" || true
  done
  for registry in $(k3d registry list -o json 2>/dev/null \
      | awk -F'"' '/"name":/ && /homelab/ {print $4}'); do
    k3d registry delete "$registry" || true
  done
fi

if command -v docker >/dev/null; then
  docker network rm homelab-net 2>/dev/null || true
  if [[ "$PRUNE_VOLUMES" == "true" ]]; then
    docker volume prune -f --filter 'label=homelab' || true
  fi
fi

echo "Done."
