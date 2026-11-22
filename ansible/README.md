# ansible/

Config management for the k3s host.

Roles:

- `base` — users, SSH hardening, timezone, unattended-upgrades.
- `docker` — Docker CE from upstream repo.
- `fail2ban` — SSH jail.
- `node_exporter` — systemd service.
- `k3s` — single-node install, Traefik disabled.

Inventory is generated from Terraform output.

`base`, `docker` and `fail2ban` have Molecule scenarios (Docker driver).
`k3s` is validated against a real VM; Molecule-on-Docker fights systemd and
cgroups and the signal-to-noise isn't worth it.
