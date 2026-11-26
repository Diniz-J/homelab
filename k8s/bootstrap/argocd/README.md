# k8s/bootstrap/argocd/

One-time manual install of ArgoCD. After this, ArgoCD owns everything under
`k8s/apps/` via GitOps — nothing else here goes through `kubectl apply` by
hand.

## Install

Assumes the cluster from `terraform apply` is reachable at the
`k3d-homelab` kubectl context.

```
kubectl --context k3d-homelab apply -k k8s/bootstrap/argocd/
kubectl --context k3d-homelab -n argocd rollout status deploy/argocd-server --timeout=5m
```

## Initial admin password

```
kubectl --context k3d-homelab -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

## Access the UI

Port-forward (easiest for local):

```
kubectl --context k3d-homelab -n argocd port-forward svc/argocd-server 8081:443
```

Then open https://localhost:8081. Username `admin`, password from the step
above.

## Upgrade

Bump the pinned version in `kustomization.yaml` (`v2.12.6` -> whatever is
current) and re-apply with the same command.

## KSOPS sidecar

`argocd-repo-server-patch.yaml` is a strategic merge patch that mounts
a shared `emptyDir`, installs the `viaductoss/ksops:v4.3.3` binary
through an init container, mounts the `argocd-age-key` Secret and sets
`XDG_CONFIG_HOME` / `SOPS_AGE_KEY_FILE`. From then on, Applications
can use the KSOPS kustomize generator to decrypt `*.enc.yaml` on
sync.

The age-key Secret is mounted with `optional: true`, so the pod
starts before anyone creates the Secret; only Applications that
actually reference KSOPS fail until the Secret is in place.

Create the Secret before syncing anything that needs it (see
[ADR 0005](../../../docs/adr/0005-argocd-sops-integration.md) and
[`docs/secrets.md`](../../../docs/secrets.md)):

```
kubectl --context k3d-homelab -n argocd create secret generic argocd-age-key \
  --from-file=keys.txt=$HOME/.config/sops/age/keys.txt
kubectl --context k3d-homelab -n argocd rollout restart deploy/argocd-repo-server
```

## What's next

ArgoCD syncs everything under `k8s/apps/` from here on. The root
`Application` in `k8s/apps/root.yaml` is the single thing you
`kubectl apply` by hand after this bootstrap.
