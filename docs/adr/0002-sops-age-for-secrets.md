# ADR 0002 — SOPS + age for secrets across all layers

Status: accepted

## Context

Three layers need secrets handled:

- Terraform: OCI API keys, DuckDNS token, Telegram bot token.
- Ansible: SSH keys, service tokens.
- Kubernetes: Let's Encrypt account key, Alertmanager Telegram secret, backup
  bucket credentials.

Options:

- **sealed-secrets**: Kubernetes-only. Means picking a separate tool for
  Terraform and Ansible.
- **SOPS + age**: covers all three layers with the same workflow.
- **External secret manager** (Vault, AWS Secrets Manager, OCI Vault): real
  answer for production, overkill for a single-node lab and adds cost.

## Decision

Standardize on SOPS + age across all layers.

## Consequences

Positive:

- One tool, one key, one mental model.
- age keys are short and easy to rotate.
- Encrypted files are plain enough to diff in PRs.
- Works offline.

Negative:

- The age private key needs to live somewhere that isn't the repo. For now:
  local disk + password manager.
- CI needs the private key injected as a GitHub Actions secret, which is one
  secret-at-rest that isn't in SOPS. Acceptable trade-off.
- No central audit trail. Again, acceptable for a lab; a real production setup
  would use a proper secret manager.

## Revisit when

- The number of people with the private key grows past one.
- I wire up anything that would benefit from short-lived secrets (dynamic DB
  credentials, for instance).
