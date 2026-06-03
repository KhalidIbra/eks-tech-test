.PHONY: infra bootstrap deploy

infra:
	cd terraform/environments/dev && terraform apply

bootstrap:
	./scripts/bootstrap.sh

deploy: infra bootstrap
	@echo "Cluster is bootstrapped. ArgoCD will sync the rest from Git."

destroy:
	./scripts/teardown.sh

