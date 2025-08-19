.PHONY: help secret-argocd pf-argocd bootstrap-flux-dev bootstrap-flux-prd flux-status flux-logs init-dev init-prd up-dev up-prd destroy-dev destroy-prd clean logs-dev logs-prd status-dev status-prd setup-env flux-refresh flux-refresh-bruno

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# Pulumi Operations
# =============================================================================

init-studio: ## Initialize Pulumi studio stack
	cd pulumi && pulumi stack init studio

up-studio: ## Deploy studio stack (Mac Studio)
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
	cd pulumi && pulumi stack select studio && pulumi refresh --yes && pulumi up --yes

destroy-studio: ## Destroy studio stack
	cd pulumi && pulumi stack select studio && pulumi destroy --yes

refresh-studio: ## Refresh Pulumi state against cluster
	cd pulumi && pulumi stack select studio && pulumi refresh --yes

setup-env: ## Setup environment variables for GitHub and Cloudflare authentication
	@echo "Setting up environment variables for GitHub and Cloudflare authentication..."
	@echo ""
	@echo "=== GitHub Authentication ==="
	@echo "Please ensure you have a GitHub Personal Access Token with the following scopes:"
	@echo "  - repo (full control of private repositories)"
	@echo "  - workflow (update GitHub Action workflows)"
	@echo ""
	@echo "You can create a token at: https://github.com/settings/tokens"
	@echo ""
	@echo "=== Cloudflare Authentication ==="
	@echo "For DDNS functionality, you need a Cloudflare API token with the following permissions:"
	@echo "  - Zone:Zone:Read"
	@echo "  - Zone:DNS:Edit"
	@echo ""
	@echo "You can create a token at: https://dash.cloudflare.com/profile/api-tokens"
	@echo ""
	@echo "=== Environment Variables ==="
	@echo "Set the following environment variables:"
	@echo "  export GITHUB_TOKEN=your_github_personal_access_token"
	@echo "  export GITHUB_USERNAME=your_github_username (optional, defaults to brunovlucena)"
	@echo "  export CLOUDFLARE_TOKEN=your_cloudflare_api_token"
	@echo ""
	@echo "Or add them to your shell profile (~/.zshrc, ~/.bashrc, etc.)"

# =============================================================================
# Flux Operations
# =============================================================================

flux-refresh: ## Force refresh all Flux HelmRepositories
	@echo "🔄 Forcing refresh of all Flux HelmRepositories..."
	kubectl annotate helmrepository --all -n flux-system --overwrite reconcile.fluxcd.io/requestedAt="$$(date +%s)"
	@echo "✅ Flux HelmRepositories refresh triggered"

flux-refresh-bruno: ## Force refresh bruno-site chart specifically
	@echo "🔄 Forcing refresh of bruno-site-chart HelmRepository..."
	kubectl annotate helmrepository bruno-site-chart -n flux-system --overwrite reconcile.fluxcd.io/requestedAt="$$(date +%s)"
	@echo "✅ Bruno-site-chart HelmRepository refresh triggered"
	@echo "🔄 Forcing refresh of bruno-site HelmRelease..."
	kubectl annotate helmrelease bruno-site -n bruno --overwrite reconcile.fluxcd.io/requestedAt="$$(date +%s)"
	@echo "✅ Bruno-site HelmRelease refresh triggered"
	@echo "⏳ Waiting 30 seconds for Flux to process..."
	sleep 30
	@echo "📊 Current HelmRelease status:"
	kubectl get helmrelease bruno-site -n bruno -o wide
	@echo "📊 Current HelmChart status:"
	kubectl get helmchart -n flux-system | grep bruno