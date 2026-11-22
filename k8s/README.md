# k8s/

Kubernetes manifests. ArgoCD syncs everything under `apps/` from this folder.

Layout:

- `bootstrap/argocd/` — one-time manual `kubectl apply`. Installs ArgoCD and
  the root Application that points back at `apps/`.
- `apps/` — everything ArgoCD owns: Traefik, cert-manager, observability stack,
  backup, demo workload.
- `overlays/prd/` and `overlays/dev/` — Kustomize overlays. `prd` targets the
  Oracle host; `dev` targets a local k3d cluster with `*.localhost` hostnames.
