# ADR 0005 — ArgoCD + SOPS integration via a KSOPS sidecar

Status: accepted. Wired into `k8s/bootstrap/argocd/` via a strategic
merge patch; the `argocd-age-key` Secret is operator-created on a
fresh cluster.

## Context

[ADR 0002](0002-sops-age-for-secrets.md) committed the lab to SOPS +
age. Today the Alertmanager Telegram Secret documented in
[`docs/alerting-telegram.md`](../alerting-telegram.md) is applied by
hand after a local `sops --decrypt`, because nothing in the cluster
knows how to render encrypted files from the git tree.

That's a single-Secret workaround. Any additional encrypted file (a
rotated `homelab-ca` key pair, a Grafana admin password, a MinIO
root rotation, a cloud overlay's provider credentials) would replay
the same ceremony. Need a GitOps-native way for ArgoCD to decrypt
`*.enc.yaml` files during sync.

## Options considered

- **KSOPS as a Kustomize plugin sidecar** (viaduct-ai/kustomize-sops).
  The ArgoCD `argocd-repo-server` grows a KSOPS binary (installed by
  an init container) and a volume-mounted age private key. Kustomize
  invokes KSOPS as a generator; any `*.enc.yaml` the generator points
  at is decrypted in-flight.
- **argocd-vault-plugin (AVP)** with a SOPS backend. Native Config
  Management Plugin shape, but the SOPS backend is less exercised
  than KSOPS in the field, and AVP's templating syntax is more
  surface than I want for a lab.
- **Helm Secrets.** Works for Helm sources only; the lab uses
  Kustomize everywhere except the upstream chart `Application`s,
  which don't ship Secrets from git anyway.

## Decision

Go with **KSOPS** as a kustomize generator plugin, installed into
`argocd-repo-server` via an init container plus a secret-mounted age
key.

## Consequences

Positive:

- Keeps the SOPS + Kustomize chain the repo already uses; no new
  tool, no new templating language.
- Any file matching `**/*.enc.yaml` becomes renderable from git.
  Alertmanager, Grafana admin, future provider credentials all come
  along for the ride.
- The age private key stays out of git and off the host — it lives
  in exactly one Kubernetes `Secret`, backed up outside the cluster.

Negative:

- The `argocd-repo-server` Deployment picks up a non-trivial
  strategic merge patch (volumes + init container + volume mounts +
  env). Upgrading ArgoCD means re-reviewing the patch.
- First-time onboarding gains one more step (install KSOPS keypair,
  create the Secret, re-sync `argocd` namespace). Documented in
  [`docs/examples/argocd-sops/`](../examples/argocd-sops/).
- An Application that uses KSOPS for the first time can take a few
  minutes to reconcile — repo-server caches aggressively. Not a
  correctness issue, but a UX wart.

## Rollout

- [`k8s/bootstrap/argocd/argocd-repo-server-patch.yaml`](../../k8s/bootstrap/argocd/argocd-repo-server-patch.yaml)
  carries the strategic merge patch. The bootstrap kustomization
  applies it; nothing more to wire.
- The `argocd-age-key` Secret is `optional: true` on the volume, so
  `argocd-repo-server` starts cleanly before the Secret exists. Only
  Applications that actually reference the KSOPS generator fail
  until the Secret is in place.
- First encrypted file to migrate off the manual
  `sops --decrypt | kubectl apply` ceremony is
  `alertmanager-telegram` — see
  [`docs/alerting-telegram.md`](../alerting-telegram.md). Still a
  follow-up PR.

## Revisit when

- An upstream ArgoCD release bundles KSOPS or an equivalent plugin
  natively — then the sidecar can go.
- The lab outgrows a single age key (team of two or more) — then move
  to a multi-recipient `.sops.yaml` and run the drill for everyone.
