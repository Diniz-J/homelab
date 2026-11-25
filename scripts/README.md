# scripts/

One-off helpers that don't belong in Terraform or Ansible.

Available:

- `pull-backup.sh` — rclone sync from the in-cluster MinIO bucket
  `homelab-backup` to a local directory. Opens a kubectl port-forward
  on demand and tears it down on exit. Env-var overrides for
  everything the defaults lie about.

Planned:

- `dev-up.sh` / `dev-down.sh` — bring a local k3d cluster up with ArgoCD
  pointing at the dev overlay.
- `bootstrap-oci-state.sh` — thin wrapper that runs the `bootstrap/` TF
  stack with the right OCI credentials loaded (parked with the cloud
  overlay).
