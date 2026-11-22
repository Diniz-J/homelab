# terraform/

Main infrastructure stack: VCN, subnet, security list, Ampere A1 instance,
DuckDNS record, backup bucket.

Backend lives in the Object Storage bucket created by `bootstrap/`.

Outputs feed the Ansible inventory.
