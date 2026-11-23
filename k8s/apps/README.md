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
- `kube-prometheus-stack` — Prometheus Operator, Prometheus, Grafana and
  Alertmanager via the upstream Helm chart. Grafana reachable at
  `https://grafana.homelab.localhost`. Prometheus picks up every
  `ServiceMonitor` / `PodMonitor` / `PrometheusRule` in the cluster.
  `sync-wave: "15"` so the `homelab-ca` issuer is ready for the ingress.
- `loki` — Loki in `SingleBinary` mode with filesystem storage and a
  7-day retention. Scalable / distributed components, caches, gateway
  and self-monitoring are all off; this is a lab, not a tenant.
  `sync-wave: "15"`.
- `alloy` — Grafana Alloy as a DaemonSet. One River pipeline:
  Kubernetes pod discovery → relabel to `namespace`/`pod`/`container`/`app`
  → push to Loki in `monitoring`. `sync-wave: "20"`, so Loki's endpoint
  exists before the first push.
- `go-sample` — the demo workload (source under
  [`workloads/go-sample/`](../../workloads/go-sample/)). Exposes
  `/healthz`, `/metrics` and `/boom`, reachable at
  `https://go-sample.homelab.localhost` with a certificate from the
  `homelab-ca` issuer. `sync-wave: "20"` so the issuer is ready first.

## What's next

- Alertmanager routed to Telegram
- MinIO + backup CronJob
