#!/usr/bin/env bash
# Rotate SOPS data keys on every encrypted file in the repo after a
# recipient change in .sops.yaml -- new age public key added for a new
# operator, an existing one revoked, that kind of thing.
#
# Walks every path a creation_rule in .sops.yaml claims. For each
# *.enc.yaml below it, runs `sops updatekeys --yes`, which re-encrypts
# the per-file data key against the current recipient list without
# touching the secret payload.
#
# No argument means "every file under secrets/ and k8s/"; pass one or
# more paths to narrow the drill.
#
# Env-var overrides:
#   DRY_RUN=true   prints what would be touched, changes nothing.

set -euo pipefail

if ! command -v sops >/dev/null; then
  echo "sops not found. See docs/secrets.md for install instructions." >&2
  exit 1
fi

DRY_RUN="${DRY_RUN:-false}"
ROOTS=("${@:-secrets k8s}")

mapfile -t files < <(find "${ROOTS[@]}" -type f -name '*.enc.yaml' 2>/dev/null | sort)

if (( ${#files[@]} == 0 )); then
  echo "No *.enc.yaml files found under: ${ROOTS[*]}"
  exit 0
fi

printf 'Found %d encrypted file(s) under: %s\n' "${#files[@]}" "${ROOTS[*]}"
printf '  %s\n' "${files[@]}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY_RUN=true; nothing changed."
  exit 0
fi

for file in "${files[@]}"; do
  printf '\n-- %s\n' "$file"
  sops updatekeys --yes "$file"
done

printf '\nDone. Review `git diff` -- updatekeys only changes the per-file data key metadata, never the payload.\n'
