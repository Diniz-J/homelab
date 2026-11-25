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

Planned:

- `bootstrap-oci-state.sh` — thin wrapper that runs the `bootstrap/` TF
  stack with the right OCI credentials loaded (parked with the cloud
  overlay).
