# Architecture

## Overview

```
                      GitHub
                        |
                        | OIDC
                        v
            +-------------------------+
            |   GitHub Actions CI     |
            |  lint / plan / apply    |
            +-----------+-------------+
                        |
                        v
      +--------------------------------------+
      |   Oracle Cloud (sa-saopaulo-1)       |
      |                                      |
      |   +------------------------------+   |
      |   | ARM Ampere A1 VM (k3s node)  |   |
      |   |                              |   |
      |   |  Traefik + cert-manager      |   |
      |   |  ArgoCD                      |   |
      |   |  Alloy / Prometheus / Loki   |   |
      |   |  Grafana / Alertmanager      |   |
      |   |  Backup CronJob              |   |
      |   |  go-sample (demo workload)   |   |
      |   +------------------------------+   |
      |                                      |
      |   Object Storage                     |
      |   - tf-state                         |
      |   - backups (primary)                |
      +------------------+-------------------+
                         |
                         | rclone pull
                         v
                 Local PC (cold copy)

                         |
                         | webhook
                         v
                   Telegram bot
```

## Layers

### 1. Terraform

Provisions infrastructure on Oracle Cloud Free Tier:

- **network/**: VCN, public subnet, security list (22 restricted, 80/443 open).
- **compute/**: Ampere A1 instance (ARM), cloud-init bootstraps the SSH key.
- **dns/**: DuckDNS record updated via `local-exec` (no official provider).
- **storage/**: Object Storage bucket for backups, with lifecycle policy.

State lives in Object Storage, with locking. The bucket itself is created by the
one-shot stack in `bootstrap/`, which keeps its state locally (committed as
encrypted JSON via SOPS).

### 2. Ansible

Takes the host from "fresh Ubuntu" to "k3s node ready":

- **base**: users, SSH hardening, timezone, unattended-upgrades.
- **docker**: Docker CE from upstream repo.
- **fail2ban**: SSH jail.
- **node_exporter**: systemd service, scraped by Prometheus.
- **k3s**: single-node install, with Traefik disabled (we install our own).

Inventory is generated from Terraform output.

Base, docker and fail2ban are tested with Molecule (Docker driver). k3s is
tested against a real VM — Molecule with the Docker driver fights systemd and
cgroups, and the signal-to-noise is poor.

### 3. Kubernetes (k3s)

Bootstrap is a one-time manual `kubectl apply` of the ArgoCD manifests under
`k8s/bootstrap/argocd/`. After that, ArgoCD syncs everything under `k8s/apps/`
from this repo.

- **Ingress**: Traefik v3 as a Helm release, LoadBalancer bound to the host
  public IP.
- **TLS**: cert-manager with a Let's Encrypt ClusterIssuer (HTTP-01).
- **Observability**:
  - Grafana Alloy as the single collector agent (metrics + logs).
  - Prometheus scrapes node_exporter, kube-state-metrics and app `/metrics`.
  - Loki stores logs, Alloy pushes.
  - Grafana ships with provisioned dashboards (node, k8s, app).
  - Alertmanager routes to a Telegram webhook.
- **Secrets**: SOPS + age. Private key lives on the host and on my laptop; never
  in the repo.
- **Backup**: CronJob dumps the k3s SQLite datastore and the manifests tree to
  Object Storage. rclone on my laptop pulls the bucket weekly.
- **Demo workload**: a small Go app exposing `/healthz`, `/metrics`, and a
  `/boom` endpoint that returns 500s to exercise the alerting pipeline and
  ArgoCD rollback.

### 4. Local dev

`make dev-up` spins a k3d cluster locally, installs ArgoCD, and points it at the
same repo (dev overlay). This lets me iterate on manifests without touching
production.

## Resource budget

k3s + the full observability stack + ArgoCD + Traefik + cert-manager fits
comfortably in 8 GB RAM. The Ampere A1 free tier gives 4 vCPU and 24 GB, which
leaves headroom for one or two extra apps.

## What the lab *doesn't* try to do

- **HA**: it's a single node. HA would require three nodes and a real etcd,
  which defeats the point of the free tier.
- **Multi-tenant**: no namespace-level isolation, no RBAC beyond defaults.
- **Production-grade DR**: the backup is a cold copy pull. For real DR I'd want
  an off-account backup target.
