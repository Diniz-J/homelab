# k8s/apps/

Everything ArgoCD owns.

## Pattern

`root.yaml` is the one `Application` you `kubectl apply` by hand, right
after bootstrapping ArgoCD (see [`../bootstrap/argocd/`](../bootstrap/argocd/)).
It points at `_root/`, which is a Kustomize overlay listing every leaf
`Application`. Adding a new app means:

1. Drop its `Application` manifest under `_root/<name>.yaml`.
2. Reference it from `_root/kustomization.yaml`.
3. Commit. ArgoCD picks it up on the next sync.

That's it — no bespoke scripting, no ApplicationSet gymnastics for a
single-cluster lab. If this ever grows to more than ~10 apps or a second
cluster, migrating to an `ApplicationSet` with a git-directories generator
is a one-PR move.

## First install

```
kubectl --context k3d-homelab apply -f k8s/apps/root.yaml
```

From there, ArgoCD syncs every leaf.

## Current apps

- `traefik` — ingress controller via upstream Helm chart. Default
  IngressClass, logs enabled.
- `cert-manager` — certificate controller via upstream Helm chart. CRDs
  bundled.
- `cluster-issuers` — four `ClusterIssuer`s: a `selfsigned-root` and a
  `homelab-ca` chain for local HTTPS, plus a Let's Encrypt staging
  issuer for CI. Lives in its own folder (`cluster-issuers/`) and syncs
  after cert-manager via `sync-wave: "10"`.

## What's next

- `go-sample` (the demo workload)
- Observability stack (Alloy, Prometheus, Loki, Grafana, Alertmanager)
- MinIO + backup CronJob
