# ArgoCD + SOPS reference manifests

Reference material for the plan in
[ADR 0005](../../adr/0005-argocd-sops-integration.md). Nothing here
ships into the cluster yet — a follow-up PR copies these into
`k8s/bootstrap/argocd/` once an age keypair is in place.

## What each file is for

- [`repo-server-patch.yaml`](repo-server-patch.yaml) — strategic
  merge patch applied to the `argocd-repo-server` `Deployment`.
  Installs the KSOPS binary into a shared `emptyDir`, mounts the age
  private key, and configures the Kustomize plugin path so
  `apiVersion: viaduct.ai/v1 kind: ksops` manifests work.
- [`age-key-secret.enc.yaml.example`](age-key-secret.enc.yaml.example) —
  template for the `argocd-age-key` `Secret`. Encrypt a filled-in
  copy with SOPS before committing.

## One-time bootstrap (from a fresh clone)

```
# 1. Generate the age keypair -- see docs/secrets.md
age-keygen -o age-key.txt

# 2. Pin the public key in .sops.yaml (replace the placeholder)
# 3. Create the Secret directly; sops updatekeys gets it into git later.
kubectl --context k3d-homelab -n argocd create secret generic argocd-age-key \
  --from-file=keys.txt=age-key.txt
rm age-key.txt   # keeps your private key only in the password manager

# 4. Apply the patched bootstrap
kubectl --context k3d-homelab apply -k k8s/bootstrap/argocd/
kubectl --context k3d-homelab -n argocd rollout status deploy/argocd-repo-server
```

From then on, any `*.enc.yaml` referenced by a Kustomize generator
in a synced Application decrypts in-flight.

## Testing the chain

Encrypt a demo Secret and point a throwaway Application at it:

```
cat <<EOF > /tmp/demo.yaml
apiVersion: v1
kind: Secret
metadata:
  name: hello-from-sops
  namespace: default
stringData:
  message: hello
EOF
sops --encrypt --age "\$(cat ~/.config/sops/age/keys.txt | grep '# public key:' | awk '{print \$4}')" \
  /tmp/demo.yaml > /tmp/demo.enc.yaml
```

Drop `/tmp/demo.enc.yaml` behind a Kustomize generator in a branch,
and ArgoCD should sync it as a plain `Secret`. Rotate the key
afterwards:

```
sops updatekeys secrets/alertmanager-telegram.enc.yaml
```

## Known gotchas

- First reconcile after enabling the sidecar often takes a few
  minutes — the repo-server caches aggressively.
- Changing `.sops.yaml` recipients means running `sops updatekeys`
  on every encrypted file; forgetting one leaves it un-decryptable
  for future keys.
- The strategic merge patch targets the `argocd-repo-server`
  container by name. ArgoCD renames rarely, but worth an eyeball on
  every chart bump.
