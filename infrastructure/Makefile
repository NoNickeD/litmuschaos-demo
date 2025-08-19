.PHONY: help init plan apply destroy fmt validate clean

help:
	@echo "Available targets:"
	@echo "  init      - Initialize OpenTofu"
	@echo "  plan      - Plan infrastructure changes"
	@echo "  apply     - Apply infrastructure changes"
	@echo "  destroy   - Destroy infrastructure"
	@echo "  fmt       - Format configuration files"
	@echo "  validate  - Validate configuration"
	@echo "  clean     - Clean local state"

init:
	tofu init -upgrade

plan:
	tofu plan

apply:
	tofu apply

destroy:
	tofu destroy -auto-approve

fmt:
	tofu fmt -recursive

validate:
	tofu validate

clean:
	rm -rf .terraform* tfplan terraform.tfstate*

setup-backend:
	@echo "Creating backend storage..."
	./scripts/setup-backend.sh