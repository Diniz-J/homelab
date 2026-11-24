# homelab

Personal infrastructure lab. A full Kubernetes platform — Terraform, Ansible,
GitOps, observability, backup and CI — that you can clone and bring up on any
machine with Docker, in minutes.

Status: **work in progress** — building in public.

## What's in here

```
Terraform  --->  Ansible  --->  k3d / kind  --->  ArgoCD  --->  everything else
 (provider      (host-level           (local               (GitOps)
  modules)       config)               cluster)
```

- **Terraform** provisions the local Kubernetes cluster (k3d) and its dependencies
  (networks, volumes, registry) through standard providers. Modules are written
  so a future cloud target is an added provider, not a rewrite.
- **Ansible** configures a reference node (base, Docker, fail2ban, node_exporter,
  k3s) and is tested with Molecule. The same roles are ready to run against a
  real VM when there's one to point at.
- **k3d** runs the platform locally. Same Kubernetes API as any managed cluster.
- **ArgoCD** keeps the cluster in sync with this repo.
- **Grafana Alloy + Prometheus + Loki + Grafana + Alertmanager** for logs, metrics
  and alerts. Alerts go to a Telegram channel (the one dependency that actually
  needs internet).
- **SOPS + age** for secrets, across Terraform, Ansible and Kubernetes.
- **Backup** targets a local MinIO bucket, with `rclone` pulling a cold copy to
  the operator's disk. Restore is a documented drill.
- **CI** runs the whole thing end-to-end on every PR: spins a kind cluster,
  applies Terraform, syncs ArgoCD, hits the smoke endpoints, tears down.

## Why local-first

This repo prioritises being reproducible everywhere over being live somewhere.
Clone, `make dev-up`, you get the full platform in a few minutes. No account to
create, no credit card to add, no bill to watch.

A cloud overlay is parked under `terraform/modules/compute/cloud/` as a future
story. See [ADR 0004](docs/adr/0004-local-first-homelab.md).

## Stack

| Layer | Tool |
|---|---|
| IaC | Terraform |
| Config management | Ansible (with Molecule for base roles) |
| Orchestration | k3s via k3d (local), portable to any Kubernetes |
| GitOps | ArgoCD |
| Ingress / TLS | Traefik + cert-manager (local CA via mkcert; Let's Encrypt staging in CI) |
| Observability | Grafana Alloy, Prometheus, Loki, Grafana, Alertmanager |
| Secrets | SOPS + age |
| CI | GitHub Actions, full end-to-end apply on kind every PR |
| Object storage | MinIO (local), compatible with S3 clients |

## Quickstart (planned)

```
make dev-up       # k3d cluster + ArgoCD + sync
make smoke        # hits /healthz and /metrics on the demo app
make dev-down
```

Reference node (Ansible) under Multipass or a Docker-in-Docker container:

```
make node-up      # multipass launch + ansible-playbook site.yml
make node-down
```

## Roadmap

- [x] Scaffold and docs
- [x] Terraform: k3d cluster
- [x] ArgoCD bootstrap and app-of-apps
- [x] Traefik + cert-manager + sample app over HTTPS (local CA)
- [x] Observability stack (Prometheus, Grafana, Loki, Alloy, Alertmanager)
  with a provisioned dashboard and a routed Telegram receiver
- [x] Backup `CronJob` to MinIO + documented restore drill
- [x] CI: manifest validation (kubeconform) and end-to-end kind run on every PR
- [x] Renovate (self-hosted) + PR template
- [ ] Ansible roles (base, docker, fail2ban, node_exporter, k3s) with Molecule
- [ ] Terraform: local registry + docker network modules
- [ ] First measured backup/restore drill
- [ ] Cloud overlay (parked): same modules targeting a real provider

## Docs

- [Architecture](docs/architecture.md)
- [Secrets (SOPS + age)](docs/secrets.md)
- [Alerting via Telegram](docs/alerting-telegram.md)
- [Backup and restore drill](docs/backup-restore.md)
- [Importing the `homelab-ca` into your trust store](docs/trust-store.md)
- [ADRs](docs/adr/)
