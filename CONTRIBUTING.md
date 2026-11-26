# Contributing

This is a personal lab, but the workflow is public so others can
reuse it. If you clone the repo and want to iterate on it:

## Branches

Short, prefixed branches:

- `feat/<scope>` — new feature or role.
- `fix/<scope>` — bug fix.
- `docs/<scope>` — documentation only.
- `chore/<scope>` — build config, repo meta, dependency bumps.
- `ci/<scope>` — CI changes.
- `refactor/<scope>` — code moves and renames without behaviour
  change.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/). One
logical change per commit. Examples:

```
feat(terraform): add registry module
docs(adr): add 0005 sops + argocd integration plan
ci: run ansible-lint on PRs touching ansible/
fix(ansible): node_exporter -- keep every line under 160 chars
```

## PRs

- Open against `main`.
- Fill in the four sections from the template:
  **What / Why / How to verify / Follow-ups**.
- Squash-merge once CI is green. Auto-delete the branch.

Branch protection enforces linear history and blocks direct pushes to
`main`, including by admins.

## Documentation that moves with the change

- A new architectural decision ships as an ADR under
  [`docs/adr/`](docs/adr/). Mark older ones *superseded by* when the
  new ADR replaces them instead of editing in place.
- A new role, module or `Application` gets at least a one-line entry
  in the nearest `README.md` (ansible, terraform, k8s/apps).

## Pre-commit hooks

The repo ships [`.pre-commit-config.yaml`](.pre-commit-config.yaml)
with the usual hygiene hooks (trailing whitespace, EOF newline, LF
line endings, YAML parse, large-file guard, private-key sniff),
`shellcheck`, `terraform_fmt` + `terraform_validate`, `ansible-lint`,
`gofmt`, and `go vet`.

```
pipx install pre-commit
pre-commit install
pre-commit run --all-files
```

Everything the hooks run is also available through `make lint`, so
pre-commit is opt-in.

## Local checks before you push

### Terraform

```
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
tflint --recursive
```

### Kubernetes manifests

```
for dir in $(find k8s -name kustomization.yaml -not -path '*/bootstrap/*' -exec dirname {} \;); do
  kustomize build "$dir" | kubeconform -strict -summary -ignore-missing-schemas -schema-location default
done
```

### Ansible

```
cd ansible
ansible-lint
```

Role-level Molecule scenarios live under each role's `molecule/`
folder.

## Secrets

Any sensitive value goes through SOPS + age — see
[`docs/secrets.md`](docs/secrets.md). `.gitignore` refuses plaintext
`.yaml` under `secrets/`.
