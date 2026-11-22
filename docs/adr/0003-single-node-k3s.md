# ADR 0003 — Single-node k3s instead of multi-node or managed Kubernetes

Status: accepted

## Context

The lab needs Kubernetes to be real enough to show platform work (Ingress,
cert-manager, ArgoCD, observability, backup) but has to run on the free tier.

Options:

- **Managed (EKS, GKE, AKS, OKE)**: USD 70+ per month minimum just for the
  control plane. Rules itself out on cost.
- **Multi-node k3s or kubeadm**: three VMs, real etcd, HA story. Doesn't fit
  the free tier, and the extra complexity teaches very little that a single
  node doesn't already teach.
- **Single-node k3s**: one VM, SQLite datastore, Traefik disabled (we install
  our own). Fits the budget.

## Decision

Single-node k3s. Install Traefik ourselves so cert-manager and ingress
configuration stay under our version control.

## Consequences

Positive:

- Fits the Ampere A1 free tier with room to spare.
- SQLite datastore is trivial to back up.
- Traefik and cert-manager under GitOps feel like a real platform.

Negative:

- No HA. A single reboot takes the whole platform down. Acceptable for a lab.
- The backup story becomes central, because a lost node means a lost cluster.
  Hence ADR 0001's follow-up work on backup and documented restore.

## Revisit when

- The lab needs to serve something people actually depend on.
- Oracle gives me a second free ARM shape to use.
