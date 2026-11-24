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
| `fail2ban` | fail2ban with an SSH jail in `/etc/fail2ban/jail.d/90-homelab.local` (default/sshd blocks, systemd backend, 3 retries / 10 min / 1 h ban). |
| `node_exporter` | Pinned upstream `node_exporter` binary under `/usr/local/bin`, dedicated system user, systemd unit with `NoNewPrivileges` + `ProtectSystem`. Listens on `:9100`; handlers guarded with `when: not ansible_check_mode` so `--check` on a fresh host doesn't fail on a unit the dry-run didn't actually write. |
| `k3s` | Single-node k3s via the upstream `get.k3s.io` installer, pinned version, Traefik and `servicelb` disabled (we install our own under `k8s/apps/`). Kubeconfig copied into the admin user's `~/.kube/config`. Validated against a Multipass VM — no Molecule scenario, see below. |

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
which ships with a working `systemd`. `base`, `docker`, `fail2ban`
and `node_exporter` test this way. `k3s` is validated against a real
Multipass VM — Docker-in-Docker with systemd and cgroups isn't worth
fighting for a portfolio lab.

### Testing `k3s` in Multipass

```
multipass launch --name homelab-k3s --cpus 2 --memory 4G --disk 20G 22.04
multipass info homelab-k3s | awk '/IPv4/ {print $2}'

# add the host to an inventory and point the playbook at just the k3s role
cat > inventory/multipass.yml <<EOF
all:
  hosts:
    homelab-k3s:
      ansible_host: <ip-from-above>
      ansible_user: ubuntu
EOF

ansible-playbook -i inventory/multipass.yml playbooks/site.yml --tags k3s
multipass exec homelab-k3s -- sudo kubectl get nodes

multipass delete homelab-k3s && multipass purge
```
