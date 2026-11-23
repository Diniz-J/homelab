# terraform/

Main infrastructure stack. Provisions the local k3d cluster and (in follow-ups)
its networks, registry, volumes and the MinIO bucket used for backup.

State is local, in-tree, and ignored by git. A future cloud overlay keeps its
own remote state — see [ADR 0004](../docs/adr/0004-local-first-homelab.md).

## Modules

- `modules/cluster/` — creates and destroys the k3d cluster, wires the host
  port mappings and disables the built-in Traefik (we install our own under
  `k8s/apps/traefik/`).

## Prerequisites

- Terraform `>= 1.6`
- Docker
- [k3d](https://k3d.io)

## Usage

```
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

Destroy:

```
terraform -chdir=terraform destroy
```

## Variables

| Name | Default | Description |
|---|---|---|
| `cluster_name` | `homelab` | Cluster name; the kubectl context becomes `k3d-<name>`. |
| `k3s_version` | `v1.31.3-k3s1` | k3s image tag. |
| `http_port` | `8080` | Host port mapped to loadbalancer :80. |
| `https_port` | `8443` | Host port mapped to loadbalancer :443. |
