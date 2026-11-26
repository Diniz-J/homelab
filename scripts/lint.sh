#!/usr/bin/env bash
# Local pre-push lint: mirrors every static gate CI runs.
#
# Each stage is skipped when its tooling isn't installed, with a short
# warning. Nothing stops the pipeline cold -- the whole thing runs so
# you see every gap in one go.
#
# Opt-out an individual stage with SKIP_<STAGE>=true, e.g.
# SKIP_E2E=true SKIP_GO=true ./scripts/lint.sh (no E2E here anyway,
# the name is reserved for future use).

set -uo pipefail

bold()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
pass()  { printf '  \033[32mOK\033[0m   %s\n' "$*"; }
skip()  { printf '  \033[33m--\033[0m   %s\n' "$*"; }
fail()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; }

rc=0

run() {
  local name="$1"; shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
    rc=1
  fi
}

#######################################
bold "Terraform"
#######################################
if [[ "${SKIP_TERRAFORM:-false}" == "true" ]]; then
  skip "terraform (SKIP_TERRAFORM=true)"
elif ! command -v terraform >/dev/null; then
  skip "terraform not installed"
else
  run "terraform fmt -check -recursive"  terraform -chdir=terraform fmt -check -recursive
  run "terraform init -backend=false"    terraform -chdir=terraform init -backend=false -input=false >/dev/null
  run "terraform validate"               terraform -chdir=terraform validate
  if command -v tflint >/dev/null; then
    ( cd terraform && tflint --init >/dev/null 2>&1 || true )
    run "tflint --recursive"             bash -c "cd terraform && tflint --recursive"
  else
    skip "tflint not installed"
  fi
fi

#######################################
bold "Kubernetes manifests"
#######################################
if [[ "${SKIP_K8S:-false}" == "true" ]]; then
  skip "k8s manifests (SKIP_K8S=true)"
elif ! command -v kustomize >/dev/null || ! command -v kubeconform >/dev/null; then
  if ! command -v kustomize >/dev/null;    then skip "kustomize not installed"; fi
  if ! command -v kubeconform >/dev/null;  then skip "kubeconform not installed"; fi
else
  crds='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
  while IFS= read -r file; do
    dir=$(dirname "$file")
    # Same skip as the CI workflow: bootstrap/argocd pulls the ~25 MB
    # upstream install.yaml at build time.
    [[ "$dir" == "k8s/bootstrap/argocd" ]] && { skip "$dir (upstream chart fetch)"; continue; }
    if kustomize build "$dir" 2>/dev/null \
        | kubeconform -strict -summary -ignore-missing-schemas \
            -schema-location default -schema-location "$crds" >/dev/null 2>&1; then
      pass "$dir"
    else
      fail "$dir"
      rc=1
    fi
  done < <(find k8s -name kustomization.yaml)
fi

#######################################
bold "Ansible"
#######################################
if [[ "${SKIP_ANSIBLE:-false}" == "true" ]]; then
  skip "ansible-lint (SKIP_ANSIBLE=true)"
elif ! command -v ansible-lint >/dev/null; then
  skip "ansible-lint not installed"
else
  run "ansible-lint" bash -c "cd ansible && ansible-lint"
fi

#######################################
bold "Go (workloads/go-sample)"
#######################################
if [[ "${SKIP_GO:-false}" == "true" ]]; then
  skip "go (SKIP_GO=true)"
elif ! command -v go >/dev/null; then
  skip "go not installed"
else
  run "gofmt -l"  bash -c '[[ -z "$(gofmt -l workloads/go-sample)" ]]'
  run "go vet"    bash -c "cd workloads/go-sample && go vet ./..."
fi

exit "$rc"
