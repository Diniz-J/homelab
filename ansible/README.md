# ansible/

Host-level configuration. The lab is local-first — these roles aren't
strictly needed to bring up k3d — but they're the path onto any real
VM the moment one shows up, and they cover the "config management"
layer of the portfolio story.

## Roles

| Role | What it does |
|---|---|
| `base` | Timezone, package baseline, admin user with passwordless sudo, `sshd` hardening (no root login, no passwords), unattended-upgrades. |
| `docker` | Docker Engine from the upstream Ubuntu repo (`docker-ce`, `docker-ce-cli`, `containerd.io`, buildx and compose plugins). Daemon enabled and started, admin user added to the `docker` group. |

Planned, in roadmap order:

- `fail2ban` — SSH jail.
- `node_exporter` — systemd service scraped by Prometheus.
- `k3s` — single-node install, Traefik disabled.

## Running

```
cd ansible
ansible-playbook -i inventory/<env>.yml playbooks/site.yml
```

`inventory/example.yml` is a template. Real inventories live in
`inventory/<env>.yml` and are gitignored.

## Testing

Each role has a Molecule scenario under `roles/<name>/molecule/default/`.

```
cd ansible/roles/base
molecule converge
molecule verify
molecule destroy
```

The driver is Docker with `geerlingguy/docker-ubuntu2204-ansible`,
which ships with a working `systemd`. The `base`, `docker` and
`fail2ban` roles test this way. `k3s` is validated against a real
Multipass VM — Docker-in-Docker with systemd and cgroups is not worth
fighting for a portfolio lab.
