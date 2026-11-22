# secrets/

Encrypted secrets, managed with SOPS + age.

The private key never lives here. Only `.sops.yaml` (the ruleset) and
`*.enc.yaml` (the encrypted payloads) belong in git.

See [ADR 0002](../docs/adr/0002-sops-age-for-secrets.md).
