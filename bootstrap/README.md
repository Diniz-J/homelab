# bootstrap/

Reserved for a future one-shot stack that creates the remote Terraform state
backend once the lab targets a cloud provider.

Not used in local-first mode: the main Terraform stack keeps its state on disk,
and that's fine for a single-operator lab.

See [ADR 0004](../docs/adr/0004-local-first-homelab.md).
