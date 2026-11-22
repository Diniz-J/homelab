# bootstrap/

One-shot Terraform stack that creates the Object Storage bucket used as the
remote backend for the main `terraform/` stack.

Keeps its own state locally, encrypted with SOPS, because it has to exist
before any remote backend does.

Run once, then forget.
