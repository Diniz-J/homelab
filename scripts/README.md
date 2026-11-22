# scripts/

One-off helpers that don't belong in Terraform or Ansible.

Planned:

- `bootstrap-oci-state.sh` — thin wrapper that runs the `bootstrap/` TF stack
  with the right OCI credentials loaded.
- `dev-up.sh` / `dev-down.sh` — bring a local k3d cluster up with ArgoCD
  pointing at the dev overlay.
