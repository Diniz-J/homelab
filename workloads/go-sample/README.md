# workloads/go-sample

Minimal Go service used as the lab's demo workload.

Endpoints:

- `GET /healthz` — returns `ok` with HTTP 200 while healthy, `broken` with
  HTTP 500 once `/boom` has toggled it.
- `GET /boom` — toggles the "broken" flag. Used to exercise alerting and
  ArgoCD rollback flows.
- `GET /metrics` — Prometheus text format, two counters:
  `homelab_healthz_total` and `homelab_boom_total`.

Stdlib only, so there's no vendored dependency tree. Built as a scratch
distroless image.

## Local

```
cd workloads/go-sample
go run .
curl localhost:8080/healthz
curl localhost:8080/metrics
```

## Container

The image is built and pushed to `ghcr.io/diniz-j/go-sample` by the
`go-sample` GitHub Actions workflow on every merge to `main`.
