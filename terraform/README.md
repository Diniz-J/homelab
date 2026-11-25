# terraform/

Main infrastructure stack. Provisions the local k3d cluster, the
Docker network it joins and a local image registry pushed images land
on without going through Docker Hub.

State is local, in-tree, ignored by git. A future cloud overlay keeps
its own remote state — see [ADR 0004](../docs/adr/0004-local-first-homelab.md).

## Modules

- `modules/network/` — dedicated Docker bridge network. k3d joins it
  via `--network`.
- `modules/registry/` — k3d-managed local registry published at
  `localhost:<host_port>`. k3d wires it into the cluster via
  `--registry-use` so pods can pull `k3d-homelab-registry:5000/...`
  by name.
- `modules/cluster/` — creates and destroys the k3d cluster, wires
  host port mappings, optional network/registry, and disables the
  built-in Traefik (we install our own under `k8s/apps/traefik/`).

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

## Push an image to the local registry

```
docker tag my-image:dev localhost:5000/my-image:dev
docker push localhost:5000/my-image:dev
```

The registry is reachable inside the cluster at
`k3d-homelab-registry:5000/my-image:dev`.

## Variables

| Name | Default | Description |
|---|---|---|
| `cluster_name` | `homelab` | Cluster name; `kubectl` context becomes `k3d-<name>`. |
| `k3s_version` | `v1.31.3-k3s1` | k3s image tag. |
| `http_port` | `8080` | Host port mapped to loadbalancer `:80`. |
| `https_port` | `8443` | Host port mapped to loadbalancer `:443`. |
| `network_name` | `homelab-net` | Docker bridge network the cluster joins. |
| `registry_name` | `homelab-registry` | Short registry name; `k3d-` prefix added. |
| `registry_host_port` | `5000` | Host port the registry publishes. |
