# ADR 0004 — Local-first homelab, cloud target parked

Status: accepted. Supersedes [ADR 0001](0001-oracle-free-tier.md).

## Context

ADR 0001 picked Oracle Cloud Free Tier as the host. In practice, the Oracle
signup requires a credit card for verification, which is a blocker right now.
Every other cloud with a comparable free tier (AWS, GCP, Hetzner, Fly, Linode,
DigitalOcean) has the same requirement. Pre-paid and virtual cards are usually
refused during fraud checks.

The options were:

- **Wait** until a credit card is available. The repo sits empty.
- **Pivot to local-first**. The platform runs on k3d on the operator's laptop,
  and the whole thing is exercised end-to-end by CI on a GitHub Actions runner.
- **Pay a cheap Brazilian VPS** (Hostinger, around R$ 15/month, accepts PIX).
  Smaller free tier story, still costs money monthly.

## Decision

Go local-first. Build the platform against k3d locally. Keep the Terraform
modules shaped so a cloud target is a sibling `compute/cloud/` module, not a
rewrite. Let CI carry the burden of proving the thing works, by running the
same apply end-to-end on every PR.

## Consequences

Positive:

- The project starts today. No dependency on paying for anything.
- Zero running cost, ever.
- A green CI run is stronger evidence than a live URL — anyone can prove the
  stack works by rerunning the workflow.
- `make dev-up` works on any machine with Docker. The whole lab is cloneable.
- The code written now is portable. Moving to a cloud later is adding a module
  and flipping a variable.

Negative:

- No live public URL. The README leans on asciinema recordings and screenshots
  instead.
- No real certificate chain in local mode. Local uses a self-signed CA via
  mkcert; CI uses Let's Encrypt staging to keep the path honest.
- No stories of real production operation. For a junior-to-mid portfolio,
  this is acceptable. For a senior story it would not be.
- Oracle ARM constraints (idle reclaim, ARM-only builds) are moot now; the
  multi-arch exercise is gone.

## Revisit when

- A payment method opens up (credit card, friend's card for verification, VPS
  via PIX).
- The lab outgrows local resources.
- A hiring context specifically asks for a live production URL.
