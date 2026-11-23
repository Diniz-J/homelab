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
  bundled; `ClusterIssuer`s land in a follow-up PR.

## What's next

- `ClusterIssuer`s (self-signed for local, Let's Encrypt staging for CI)
- `go-sample` (the demo workload)
- Observability stack (Alloy, Prometheus, Loki, Grafana, Alertmanager)
- MinIO + backup CronJob
