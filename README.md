# homelab

Personal infrastructure lab. A single-node Kubernetes platform provisioned,
configured, monitored and backed up end-to-end from code.

Status: **work in progress** — building in public.

## What's in here

```
Terraform  --->  Ansible  --->  k3s  --->  ArgoCD  --->  everything else
 (cloud)        (host)        (cluster)   (GitOps)       (via GitOps)
```

- **Terraform** provisions the Oracle Cloud ARM instance, VCN, DNS and backup bucket.
- **Ansible** configures the host: base hardening, Docker, k3s, node_exporter.
- **k3s** runs the platform: Traefik, cert-manager, ArgoCD, observability stack.
- **ArgoCD** keeps the cluster in sync with this repo.
- **Grafana Alloy + Prometheus + Loki + Grafana + Alertmanager** for logs, metrics
  and alerts. Alerts go to a Telegram channel.
- **SOPS + age** for secrets, across Terraform, Ansible and Kubernetes.
- **Backup** is a CronJob snapshotting the k3s datastore and pulling it off-site.

## Stack

| Layer | Tool |
|---|---|
| IaC | Terraform |
| Config management | Ansible (with Molecule for base roles) |
| Orchestration | k3s (single node) |
| GitOps | ArgoCD |
| Ingress / TLS | Traefik + cert-manager (Let's Encrypt) |
| Observability | Grafana Alloy, Prometheus, Loki, Grafana, Alertmanager |
| Secrets | SOPS + age |
| CI | GitHub Actions (OIDC, no cloud secret in GitHub) |
| Cloud | Oracle Cloud Free Tier (Ampere A1 ARM) |
| DNS | DuckDNS (temporary; moving to a real domain later) |

## Quickstart (planned)

```
make bootstrap    # one-shot: provisions TF state bucket
make apply        # terraform apply -> host ready
make configure    # ansible-playbook site.yml -> k3s up, ArgoCD installed
# ArgoCD takes over from here
```

For local iteration:

```
make dev-up       # spins a k3d cluster, syncs the same manifests
make dev-down
```

## Roadmap

- [ ] Scaffold and docs
- [ ] Bootstrap module (Object Storage bucket for TF state)
- [ ] Network + compute + DNS Terraform modules
- [ ] Ansible roles: base, docker, fail2ban, node_exporter, k3s
- [ ] ArgoCD bootstrap and app-of-apps
- [ ] Traefik + cert-manager + sample app over HTTPS
- [ ] Observability stack with a live dashboard and a real alert
- [ ] Backup CronJob and documented restore drill
- [ ] Renovate and CI polishing

## Docs

- [Architecture](docs/architecture.md)
- [ADRs](docs/adr/)
