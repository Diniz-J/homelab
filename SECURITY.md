# Reporting security issues

Please report vulnerabilities **privately**, not as a public issue.

Open a private vulnerability report through GitHub's
[security advisories page](https://github.com/Diniz-J/homelab/security/advisories/new)
for this repository.

Include:

- Steps to reproduce.
- The impact (what an attacker gets, what breaks).
- A suggested fix if one is obvious.

I'll acknowledge within a few days and work the fix on a private
branch until an advisory is ready.

## Scope

This repo is a personal infrastructure lab. The platform runs locally
and holds no production data. The things worth reporting anyway:

- Sample code or manifests that would fail secure defaults when
  copied into a real environment (unsafe `securityContext`, overly
  permissive RBAC, unauthenticated services).
- Secrets accidentally committed in plaintext.
- Supply-chain issues with pinned chart / image / action versions
  already in the repo.

## Out of scope

- Findings that depend on changing a pinned version to a known-bad
  one.
- Reports against upstream projects (ArgoCD, cert-manager,
  Prometheus, …). Please take those directly to the upstream
  maintainers.
