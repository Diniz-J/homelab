# Secrets

All sensitive values live in git **encrypted**, with
[SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age).
The rationale lives in [ADR 0002](adr/0002-sops-age-for-secrets.md); this
doc is the walkthrough.

## Install

Windows / macOS / Linux:

```
# age
winget install FiloSottile.age           # Windows
brew install age                         # macOS
sudo apt install age                     # Debian/Ubuntu

# sops
winget install Mozilla.SOPS              # Windows
brew install sops                        # macOS
# linux: https://github.com/getsops/sops/releases
```

## One-time setup

### 1. Generate your age keypair

```
age-keygen -o age-key.txt
```

The file has two lines: a `# public key:` comment with your **recipient**,
and the long private key.

### 2. Move the private key to the SOPS lookup path

- **Linux / macOS**: `~/.config/sops/age/keys.txt`
- **Windows (PowerShell)**: `$env:APPDATA\sops\age\keys.txt`

```
# Windows
mkdir "$env:APPDATA\sops\age" -Force
Move-Item .\age-key.txt "$env:APPDATA\sops\age\keys.txt"

# Linux / macOS
mkdir -p ~/.config/sops/age
mv ./age-key.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

**Back it up to your password manager.** If the file is lost, every
secret in the repo becomes permanent garbage.

### 3. Pin your public key in `.sops.yaml`

Replace the `age1REPLACEME...` placeholders in the repo root
[`.sops.yaml`](../.sops.yaml) with the recipient from step 1. Commit the
change in its own PR.

## Day-to-day

### Create or edit an encrypted file

```
sops secrets/alertmanager-telegram.enc.yaml
```

SOPS opens your `$EDITOR` with the decrypted content. Save, exit, and
the file on disk is encrypted again. The creation rules in `.sops.yaml`
pick up the right recipient from the path.

### Inspect without editing

```
sops --decrypt secrets/alertmanager-telegram.enc.yaml
```

### Rotate the key

```
sops updatekeys secrets/alertmanager-telegram.enc.yaml
```

Run after changing the recipient in `.sops.yaml`.

## What belongs here (and what doesn't)

Encrypt and commit:

- Kubernetes `Secret` manifests (bot tokens, API keys, ACME account key).
- Terraform `.tfvars` with credentials.
- Ansible vaulted values that make more sense alongside the playbook.

Never commit, even encrypted:

- The age private key itself.
- Values someone else generated on the fly (session tokens, short-lived
  credentials). Those belong in a secret manager at runtime.

## What ArgoCD does with these

Planned, not wired: a KSOPS sidecar on `argocd-repo-server` renders
`*.enc.yaml` files during sync. See
[ADR 0005](adr/0005-argocd-sops-integration.md) for the plan and
[`docs/examples/argocd-sops/`](examples/argocd-sops/) for the
reference manifests (repo-server patch + `argocd-age-key` `Secret`
template).

Until that lands, decrypt manually and `kubectl apply` for the
single Secret the Alertmanager Telegram receiver needs — the file
stays encrypted in git either way.
