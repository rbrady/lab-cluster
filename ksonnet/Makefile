.PHONY: help show diff apply delete prune export install update list clean kubectl-apply

ENV ?= environments/mini-01
KUBECONFIG ?= ~/.kube/k0s-config

help: ## Show this help message
	@echo "Usage: make [target] [ENV=environments/mini-01] [KUBECONFIG=~/.kube/k0s-config]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  ENV         Target environment (default: environments/mini-01)"
	@echo "  KUBECONFIG  Path to kubeconfig (default: ~/.kube/k0s-config)"

show: ## Show rendered Kubernetes manifests for the environment
	tk show $(ENV)

show-yaml: ## Show rendered manifests in YAML format
	tk show $(ENV) --format=yaml

diff: ## Show diff between local config and cluster state
	tk diff $(ENV)

apply: ## Apply configuration to the cluster
	tk apply $(ENV)

apply-force: ## Apply with auto-approval (dangerous!)
	tk apply $(ENV) --dangerous-auto-approve

apply-redirect: ## Apply allowing server redirects
	tk apply $(ENV) --dangerous-allow-redirect

kubectl-apply: ## Apply using kubectl (workaround for kubeconfig issues)
	@mkdir -p output
	tk show $(ENV) --dangerous-allow-redirect > output/manifests.yaml
	KUBECONFIG=$(KUBECONFIG) kubectl apply -f output/manifests.yaml
	@rm -f output/manifests.yaml

delete: ## Delete all resources in the environment
	tk delete $(ENV)

prune: ## Remove resources that are no longer in the configuration
	tk prune $(ENV)

export: ## Export rendered manifests to output directory
	mkdir -p output
	tk export $(ENV) output/

install: ## Install jsonnet dependencies
	jb install

update: ## Update jsonnet dependencies
	jb update

list: ## List all available environments
	tk env list

validate: ## Validate jsonnet syntax
	tk show $(ENV) > /dev/null && echo "✓ Validation successful"

fmt: ## Format jsonnet files
	find . -name "*.jsonnet" -o -name "*.libsonnet" | xargs -I {} jsonnetfmt -i {}

clean: ## Clean generated files
	rm -rf output/
	rm -rf manifests/

tool-info: ## Show installed tool versions
	@echo "Tanka version:"
	@tk --version || echo "  Not installed"
	@echo ""
	@echo "jsonnet-bundler version:"
	@jb --version || echo "  Not installed"
	@echo ""
	@echo "kubectl version:"
	@kubectl version --client --short || echo "  Not installed"
	@echo ""
	@echo "jsonnetfmt version:"
	@jsonnetfmt --version || echo "  Not installed"

context: ## Show current kubectl context
	kubectl config current-context

cluster-info: ## Show cluster information
	kubectl cluster-info
