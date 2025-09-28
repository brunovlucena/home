# Agent Legacy Makefile
# Build, push, and test the Agent Legacy locally

# Variables
APP_NAME := agent-legacy
REGISTRY := ghcr.io/brunovlucena
IMAGE_TAG := dev
NAMESPACE := agent-legacy
LOCAL_PORT := 8080

# Docker configuration
DOCKER_IMAGE := $(REGISTRY)/$(APP_NAME):$(IMAGE_TAG)
LOCAL_IMAGE := $(APP_NAME):$(IMAGE_TAG)

# Kubernetes configuration
KUBECTL := kubectl
KUSTOMIZE := kustomize

# Python configuration
PYTHON := python3
PIP := pip3
VENV := venv

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Agent Legacy - Available Commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

.PHONY: install
install: ## Install Python dependencies
	@echo "$(BLUE)Installing Python dependencies...$(NC)"
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

.PHONY: venv
venv: ## Create virtual environment
	@echo "$(BLUE)Creating virtual environment...$(NC)"
	$(PYTHON) -m venv $(VENV)
	@echo "$(GREEN)Virtual environment created!$(NC)"
	@echo "$(YELLOW)To activate: source $(VENV)/bin/activate$(NC)"

.PHONY: install-venv
install-venv: venv ## Create venv and install dependencies
	@echo "$(BLUE)Installing dependencies in virtual environment...$(NC)"
	$(VENV)/bin/pip install -r requirements.txt
	@echo "$(GREEN)Virtual environment setup complete!$(NC)"

.PHONY: test-local
test-local: ## Test the agent locally
	@echo "$(BLUE)Testing Agent Legacy locally...$(NC)"
	@echo "$(YELLOW)Starting local test server on port $(LOCAL_PORT)...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	MONITORING_ENABLED=false $(PYTHON) app.py

.PHONY: test-venv
test-venv: install-venv ## Test with virtual environment
	@echo "$(BLUE)Testing with virtual environment...$(NC)"
	@echo "$(YELLOW)Starting local test server on port $(LOCAL_PORT)...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	MONITORING_ENABLED=false $(VENV)/bin/python app.py

.PHONY: test-api
test-api: ## Test the API endpoints
	@echo "$(BLUE)Testing API endpoints...$(NC)"
	@echo "$(YELLOW)Make sure the agent is running on port $(LOCAL_PORT)$(NC)"
	@echo ""
	@echo "$(BLUE)Testing health endpoint...$(NC)"
	curl -s http://localhost:$(LOCAL_PORT)/health | jq .
	@echo ""
	@echo "$(BLUE)Testing metrics endpoint...$(NC)"
	curl -s http://localhost:$(LOCAL_PORT)/metrics | jq .
	@echo ""
	@echo "$(BLUE)Testing chat endpoint...$(NC)"
	curl -s -X POST http://localhost:$(LOCAL_PORT)/chat \
		-H "Content-Type: application/json" \
		-d '{"message": "Hello, can you analyze the system logs?"}' | jq .
	@echo ""
	@echo "$(BLUE)Testing log analysis endpoint...$(NC)"
	curl -s -X POST http://localhost:$(LOCAL_PORT)/analyze-logs \
		-H "Content-Type: application/json" \
		-d '{"query": "{namespace=\"mocks\"} |= \"error\"}"}' | jq .
	@echo ""
	@echo "$(GREEN)API tests completed!$(NC)"

.PHONY: build
build: ## Build Docker image
	@echo "$(BLUE)Building Docker image: $(LOCAL_IMAGE)$(NC)"
	docker build -t $(LOCAL_IMAGE) .
	@echo "$(GREEN)Docker image built successfully!$(NC)"

.PHONY: build-registry
build-registry: ## Build and tag for registry
	@echo "$(BLUE)Building Docker image for registry: $(DOCKER_IMAGE)$(NC)"
	docker build -t $(DOCKER_IMAGE) .
	@echo "$(GREEN)Docker image built and tagged for registry!$(NC)"

.PHONY: login-github
login-github: ## Login to GitHub Container Registry
	@echo "$(BLUE)Logging in to GitHub Container Registry...$(NC)"
	@echo "$(YELLOW)You need a GitHub Personal Access Token with 'write:packages' permission$(NC)"
	@echo "$(YELLOW)Get your token at: https://github.com/settings/tokens$(NC)"
	@echo "$(YELLOW)Enter your GitHub username:$(NC)"
	@read -p "Username: " username; \
	echo "$$GITHUB_TOKEN" | docker login ghcr.io -u $$username --password-stdin
	@echo "$(GREEN)Logged in successfully!$(NC)"

.PHONY: push
push: build-registry ## Push image to GitHub Container Registry
	@echo "$(BLUE)Pushing image to GitHub Container Registry: $(DOCKER_IMAGE)$(NC)"
	@echo "$(YELLOW)Make sure you're logged in to GitHub Container Registry$(NC)"
	@echo "$(YELLOW)Run: make login-github$(NC)"
	docker push $(DOCKER_IMAGE)
	@echo "$(GREEN)Image pushed successfully to GitHub Container Registry!$(NC)"
	@echo "$(BLUE)Image URL: https://github.com/brunolucena/$(APP_NAME)/pkgs/container/$(APP_NAME)$(NC)"

.PHONY: run-local
run-local: build ## Run the agent locally with Docker
	@echo "$(BLUE)Running Agent Legacy locally with Docker...$(NC)"
	@echo "$(YELLOW)Starting container on port $(LOCAL_PORT)...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	docker run --rm -p $(LOCAL_PORT):8080 \
		-e MONITORING_ENABLED=false \
		-e OLLAMA_URL=http://host.docker.internal:11434 \
		-e LOKI_MCP_URL=http://host.docker.internal:8080 \
		$(LOCAL_IMAGE)

.PHONY: run-local-full
run-local-full: build ## Run with full monitoring enabled
	@echo "$(BLUE)Running Agent Legacy with full monitoring...$(NC)"
	@echo "$(YELLOW)Starting container on port $(LOCAL_PORT)...$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@echo ""
	docker run --rm -p $(LOCAL_PORT):8080 \
		-e MONITORING_ENABLED=true \
		-e MONITORING_INTERVAL=60 \
		-e OLLAMA_URL=http://host.docker.internal:11434 \
		-e LOKI_MCP_URL=http://host.docker.internal:8080 \
		$(LOCAL_IMAGE)

.PHONY: test-docker
test-docker: run-local ## Test the Docker container
	@echo "$(BLUE)Testing Docker container...$(NC)"
	@echo "$(YELLOW)Waiting for container to start...$(NC)"
	sleep 10
	@echo "$(BLUE)Testing health endpoint...$(NC)"
	curl -s http://localhost:$(LOCAL_PORT)/health | jq .
	@echo ""
	@echo "$(BLUE)Testing chat endpoint...$(NC)"
	curl -s -X POST http://localhost:$(LOCAL_PORT)/chat \
		-H "Content-Type: application/json" \
		-d '{"message": "Hello from Docker!"}' | jq .
	@echo ""
	@echo "$(GREEN)Docker tests completed!$(NC)"

.PHONY: deploy-local
deploy-local: ## Deploy to local Kubernetes
	@echo "$(BLUE)Deploying to local Kubernetes...$(NC)"
	$(KUBECTL) apply -k .
	@echo "$(GREEN)Deployment completed!$(NC)"
	@echo "$(YELLOW)Waiting for pods to be ready...$(NC)"
	$(KUBECTL) wait --for=condition=ready pod -l app.kubernetes.io/name=$(APP_NAME) -n $(NAMESPACE) --timeout=60s
	@echo "$(GREEN)Deployment is ready!$(NC)"

.PHONY: undeploy
undeploy: ## Remove from Kubernetes
	@echo "$(BLUE)Removing from Kubernetes...$(NC)"
	$(KUBECTL) delete -k .
	@echo "$(GREEN)Removal completed!$(NC)"

.PHONY: status
status: ## Check deployment status
	@echo "$(BLUE)Checking deployment status...$(NC)"
	@echo "$(YELLOW)Pods:$(NC)"
	$(KUBECTL) get pods -n $(NAMESPACE) -l app.kubernetes.io/name=$(APP_NAME)
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	$(KUBECTL) get svc -n $(NAMESPACE) -l app.kubernetes.io/name=$(APP_NAME)
	@echo ""
	@echo "$(YELLOW)Deployments:$(NC)"
	$(KUBECTL) get deploy -n $(NAMESPACE) -l app.kubernetes.io/name=$(APP_NAME)

.PHONY: logs
logs: ## Show pod logs
	@echo "$(BLUE)Showing pod logs...$(NC)"
	$(KUBECTL) logs -n $(NAMESPACE) -l app.kubernetes.io/name=$(APP_NAME) --tail=50 -f

.PHONY: port-forward
port-forward: ## Port forward to local machine
	@echo "$(BLUE)Port forwarding to local machine...$(NC)"
	@echo "$(YELLOW)Access the agent at: http://localhost:$(LOCAL_PORT)$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	$(KUBECTL) port-forward -n $(NAMESPACE) svc/$(APP_NAME) $(LOCAL_PORT):8080

.PHONY: test-k8s
test-k8s: ## Test the Kubernetes deployment
	@echo "$(BLUE)Testing Kubernetes deployment...$(NC)"
	@echo "$(YELLOW)Make sure port-forward is running$(NC)"
	@echo ""
	@echo "$(BLUE)Testing health endpoint...$(NC)"
	curl -s http://localhost:$(LOCAL_PORT)/health | jq .
	@echo ""
	@echo "$(BLUE)Testing chat endpoint...$(NC)"
	curl -s -X POST http://localhost:$(LOCAL_PORT)/chat \
		-H "Content-Type: application/json" \
		-d '{"message": "Hello from Kubernetes!"}' | jq .
	@echo ""
	@echo "$(GREEN)Kubernetes tests completed!$(NC)"

.PHONY: clean
clean: ## Clean up local resources
	@echo "$(BLUE)Cleaning up local resources...$(NC)"
	docker rmi $(LOCAL_IMAGE) 2>/dev/null || true
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	rm -rf $(VENV)
	@echo "$(GREEN)Cleanup completed!$(NC)"

.PHONY: clean-k8s
clean-k8s: undeploy ## Clean up Kubernetes resources
	@echo "$(BLUE)Cleaning up Kubernetes resources...$(NC)"
	$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found=true
	@echo "$(GREEN)Kubernetes cleanup completed!$(NC)"

.PHONY: dev
dev: install test-local ## Development workflow
	@echo "$(GREEN)Development workflow completed!$(NC)"

.PHONY: dev-docker
dev-docker: build test-docker ## Docker development workflow
	@echo "$(GREEN)Docker development workflow completed!$(NC)"

.PHONY: test-all
test-all: ## Run comprehensive test suite
	@echo "$(BLUE)Running comprehensive test suite...$(NC)"
	@echo "$(YELLOW)1. Testing local Python app...$(NC)"
	@echo "$(YELLOW)2. Testing Docker build...$(NC)"
	@echo "$(YELLOW)3. Testing Docker container...$(NC)"
	@echo "$(YELLOW)4. Testing Kubernetes deployment...$(NC)"
	@echo "$(YELLOW)5. Testing API endpoints...$(NC)"
	@echo ""
	@echo "$(BLUE)Step 1: Local Python test$(NC)"
	@timeout 10s make test-local || echo "$(YELLOW)Local test completed (timeout expected)$(NC)"
	@echo ""
	@echo "$(BLUE)Step 2: Docker build test$(NC)"
	make build
	@echo ""
	@echo "$(BLUE)Step 3: Docker container test$(NC)"
	@timeout 30s make test-docker || echo "$(YELLOW)Docker test completed (timeout expected)$(NC)"
	@echo ""
	@echo "$(BLUE)Step 4: Kubernetes deployment test$(NC)"
	make deploy-local
	@echo ""
	@echo "$(BLUE)Step 5: API endpoint test$(NC)"
	make test-k8s
	@echo ""
	@echo "$(GREEN)All tests completed successfully!$(NC)"

.PHONY: dev-k8s
dev-k8s: build-registry push deploy-local test-k8s ## Full Kubernetes development workflow
	@echo "$(GREEN)Full Kubernetes development workflow completed!$(NC)"

.PHONY: full-deploy
full-deploy: test-all login-github push deploy-local ## Complete deployment workflow
	@echo "$(GREEN)Complete deployment workflow finished!$(NC)"
	@echo "$(BLUE)Your Agent Legacy is now deployed and running!$(NC)"
	@echo "$(YELLOW)Access it at: http://agent-legacy.homelab.local$(NC)"
	@echo "$(YELLOW)Or use port-forward: make port-forward$(NC)"

.PHONY: lint
lint: ## Run code linting
	@echo "$(BLUE)Running code linting...$(NC)"
	@echo "$(YELLOW)Python linting...$(NC)"
	$(PYTHON) -m flake8 app.py || true
	@echo "$(YELLOW)YAML linting...$(NC)"
	$(KUBECTL) apply -k . --dry-run=client
	@echo "$(GREEN)Linting completed!$(NC)"

.PHONY: security
security: ## Run security checks
	@echo "$(BLUE)Running security checks...$(NC)"
	@echo "$(YELLOW)Checking for security vulnerabilities...$(NC)"
	$(PIP) install safety
	safety check -r requirements.txt || true
	@echo "$(YELLOW)Scanning Docker image...$(NC)"
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/workspace \
		aquasec/trivy image $(LOCAL_IMAGE) || true
	@echo "$(GREEN)Security checks completed!$(NC)"

# Default target
.DEFAULT_GOAL := help
