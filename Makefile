.PHONY: help secret-argocd pf-argocd bootstrap-flux-dev bootstrap-flux-prd flux-status flux-logs init-studio init-homelab up-studio up-homelab destroy-studio destroy-homelab clean logs-dev logs-prd status-dev status-prd setup-env flux-refresh flux-refresh-bruno flagger-status flagger-logs promote-canary rollback-canary istio-status istio-logs istio-proxy-status

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# Pulumi Operations
# =============================================================================

init-homelab: ## Initialize Pulumi homelab stack
	cd pulumi && pulumi stack init homelab

up-homelab: ## Deploy homelab stack
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "Error: GITHUB_TOKEN environment variable is required"; \
		echo "Run 'make setup-env' for instructions"; \
		exit 1; \
	fi
	@if [ -z "$$CLOUDFLARE_TOKEN" ]; then \
		echo "Error: CLOUDFLARE_TOKEN environment variable is required"; \
		echo "Run 'make setup-env' for instructions"; \
		exit 1; \
	fi
	cd pulumi && pulumi stack select homelab && pulumi refresh --yes && pulumi up --yes

destroy-homelab: ## Destroy homelab stack
	cd pulumi && pulumi stack select homelab && pulumi destroy --yes

# =============================================================================
# Flux Operations
# =============================================================================

flux-refresh: ## Force refresh all Flux HelmRepositories, GitRepositories, and HelmReleases
	@echo "🔄 Forcing refresh of all Flux resources..."
	@echo "📦 Refreshing HelmRepositories..."
	kubectl annotate helmrepository --all -n flux-system --overwrite reconcile.fluxcd.io/requestedAt="$$(date +%s)"
	@echo "📚 Refreshing GitRepositories..."
	kubectl annotate gitrepository --all -n flux-system --overwrite reconcile.fluxcd.io/requestedAt="$$(date +%s)"
	@echo "🚀 Refreshing HelmReleases..."
	kubectl annotate helmrelease --all -n flux-system --overwrite reconcile.fluxcd.io/requestedAt="$$(date +%s)"
	@echo "✅ Flux refresh triggered for all resources"