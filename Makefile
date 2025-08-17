.PHONY: help secret-argocd pf-argocd bootstrap-flux-dev bootstrap-flux-prd flux-status flux-logs init-dev init-prd up-dev up-prd destroy-dev destroy-prd clean logs-dev logs-prd status-dev status-prd setup-env

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
	cd pulumi && pulumi stack select studio && pulumi up --yes

destroy-studio: ## Destroy studio stack
	cd pulumi && pulumi stack select studio && pulumi destroy --yes

setup-env: ## Setup environment variables for GitHub authentication
	@echo "Setting up environment variables for GitHub authentication..."
	@echo "Please ensure you have a GitHub Personal Access Token with the following scopes:"
	@echo "  - repo (full control of private repositories)"
	@echo "  - workflow (update GitHub Action workflows)"
	@echo ""
	@echo "You can create a token at: https://github.com/settings/tokens"
	@echo ""
	@echo "Then set the following environment variables:"
	@echo "  export GITHUB_TOKEN=your_github_personal_access_token"
	@echo "  export GITHUB_USERNAME=your_github_username (optional, defaults to brunovlucena)"
	@echo ""
	@echo "Or add them to your shell profile (~/.zshrc, ~/.bashrc, etc.)"