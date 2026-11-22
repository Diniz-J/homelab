.PHONY: help bootstrap apply configure dev-up dev-down lint plan destroy

help:
	@echo "Targets:"
	@echo "  bootstrap    One-shot: create the TF state bucket in OCI"
	@echo "  plan         terraform plan against the production stack"
	@echo "  apply        terraform apply against the production stack"
	@echo "  configure    ansible-playbook site.yml against the provisioned host"
	@echo "  dev-up       spin a local k3d cluster and sync manifests"
	@echo "  dev-down     tear the local k3d cluster down"
	@echo "  lint         run all linters locally"
	@echo "  destroy      terraform destroy (careful)"

bootstrap:
	cd bootstrap && terraform init && terraform apply

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

configure:
	cd ansible && ansible-playbook -i inventory/prd.yml playbooks/site.yml

dev-up:
	./scripts/dev-up.sh

dev-down:
	./scripts/dev-down.sh

lint:
	cd terraform && terraform fmt -check -recursive
	cd ansible && ansible-lint

destroy:
	cd terraform && terraform destroy
