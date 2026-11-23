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

## What's next

The follow-up PR adds `k8s/apps/` and the root ArgoCD `Application` that
points ArgoCD at this repo, so every manifest under `k8s/apps/` becomes
GitOps-managed.
