# scripts/

One-off helpers that don't belong in Terraform or Ansible.

Available:

- `pull-backup.sh` — rclone sync from the in-cluster MinIO bucket
  `homelab-backup` to a local directory. Opens a kubectl port-forward
  on demand and tears it down on exit. Env-var overrides for
  everything the defaults lie about.
- `dev-up.sh` — one-shot: `terraform apply` → bootstrap ArgoCD →
  apply `root.yaml` → wait for `root` to be `Synced`. Prints how to
  reach ArgoCD, Grafana, go-sample and MinIO at the end.
- `dev-down.sh` — `terraform destroy` plus a mop-up that removes any
  `homelab`-prefixed k3d cluster/registry and the `homelab-net`
  Docker network that outlived state. `PRUNE_VOLUMES=true` also
  removes labelled Docker volumes.
- `smoke.sh` — `curl`s go-sample `/healthz`, Grafana `/api/health`
  and MinIO `/minio/health/live` through the ingress, then walks
  every ArgoCD `Application` and requires `Synced + Healthy`. Exits
  non-zero on the first miss. `HOST_SUFFIX`, `HTTPS_PORT`,
  `KUBE_CONTEXT`, `CURL_FLAGS` overrides available. Falls back to
  `python3` when `jq` isn't installed.
- `rotate-sops.sh` — runs `sops updatekeys --yes` on every
  `*.enc.yaml` the repo tracks. Walks `secrets/` and `k8s/` by
  default; pass one or more paths to scope it. `DRY_RUN=true` lists
  what would move. See
  [`docs/secrets.md`](../docs/secrets.md) for the drill.

Planned:

- `bootstrap-oci-state.sh` — thin wrapper that runs the `bootstrap/` TF
  stack with the right OCI credentials loaded (parked with the cloud
  overlay).
