# ADR 0001 — Oracle Cloud Free Tier as the hosting provider

Status: accepted

## Context

The lab needs a cloud host that can run k3s plus a full observability stack
(Prometheus, Loki, Grafana, Alertmanager, Alloy) plus ArgoCD plus Traefik plus
cert-manager plus a demo workload. That stack is honest in 8 GB of RAM; anything
smaller means cutting components or cranking retention down.

Constraints:

- Cost must be zero or near-zero. This is a personal portfolio project, not a
  production workload.
- The cloud needs to be recognizable in a resume context.
- Terraform provider has to be usable.

## Options considered

- **Oracle Cloud Free Tier (Ampere A1 ARM)**: 4 vCPU and 24 GB RAM, free forever.
  Official Terraform provider. ARM-only on the free tier.
- **AWS EC2 t4g.medium**: 4 GB RAM, around USD 24 per month after the 12-month
  free tier expires.
- **Hetzner CPX21**: 4 GB dedicated vCPUs for around EUR 8 per month. Solid
  provider but obscure outside Europe.
- **Local homelab only (k3d/kind)**: free, but no live URL means a weaker
  portfolio story.

## Decision

Go with Oracle Cloud Free Tier.

## Consequences

Positive:

- 24 GB of RAM gives room for the full stack without compromises.
- Zero cost, indefinitely.
- Forces ARM, which exercises a real multi-arch constraint on builds.

Negative:

- The "idle instance reclaim" policy can delete a VM that stays under 20% CPU
  for a week. Mitigated by a minimal always-on workload.
- Capacity in popular regions is tight. May need a less obvious region.
- The OCI name carries less weight than AWS in some hiring contexts.
- The Terraform provider is less idiomatic than AWS's.

## Revisit when

- I get enough budget to justify an EKS or GKE setup.
- Oracle changes the free tier terms.
- The lab outgrows a single node.
