# workloads/

Application source code. Separate from `k8s/apps/` so code and manifests don't
tangle.

Current apps:

- `go-sample` — minimal Go service exposing `/healthz`, `/metrics` and a
  `/boom` endpoint that returns 500s on demand. Used to exercise the observability
  and alerting pipeline, and to practice ArgoCD rollbacks.
