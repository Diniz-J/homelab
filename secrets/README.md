# secrets/

Encrypted secrets, managed with SOPS + age.

See [`docs/secrets.md`](../docs/secrets.md) for the full walkthrough
(install, keygen, where the private key lives, day-to-day usage) and
[ADR 0002](../docs/adr/0002-sops-age-for-secrets.md) for the rationale.

Only files ending in `.enc.yaml` (or `.enc.yml`) are allowed here;
`.gitignore` blocks the rest, so a plaintext `kubectl get secret -o
yaml` can't slip in by accident.

Nothing lives here yet. First real file lands with the Alertmanager →
Telegram wiring.
