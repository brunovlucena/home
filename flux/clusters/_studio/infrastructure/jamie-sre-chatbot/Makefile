# Jamie SRE Chatbot Makefile
# This Makefile manages the Jamie SRE Chatbot application

# Environment configuration
ENV ?= dev
REGISTRY ?= ghcr.io/brunovlucena/jamie-sre-chatbot
IMAGE_NAME ?= jamie-sre-chatbot

.PHONY: help build build-push clean logs status shell test format lint

# Default target
help:
	@echo "🤖 Jamie SRE Chatbot Management"
	@echo "==============================="
	@echo ""
	@echo "Environment: $(ENV)"
	@echo "Registry: $(REGISTRY)"
	@echo ""
	@echo "Available commands:"
	@echo "  make build                 - Build Docker image"
	@echo "  make build-push            - Build and push Docker image to registry"
	@echo "  make clean                 - Remove local Docker images"
	@echo "  make logs                  - Show application logs (if running locally)"
	@echo "  make status                - Show deployment status in Kubernetes"
	@echo "  make shell                 - Open shell in running container"
	@echo "  make test                  - Run tests"
	@echo "  make format                - Format Python code"
	@echo "  make lint                  - Lint Python code"
	@echo ""

# Build Docker image
build:
	@echo "🏗️ Building Docker image..."
	@echo "Environment: $(ENV)"
	@echo "Registry: $(REGISTRY)"
	@echo "Image: $(REGISTRY):$(ENV)"
	@docker build -t $(REGISTRY):$(ENV) .
	@echo "✅ Image built successfully"

# Build and push image to registry
build-push: build
	@echo "🚀 Pushing image to registry..."
	@docker push $(REGISTRY):$(ENV)
	@echo "✅ Image built and pushed successfully!"
	@echo "📋 Pushed image:"
	@echo "  $(REGISTRY):$(ENV)"

# Clean up local Docker images
clean:
	@echo "🧹 Cleaning up local Docker images..."
	@docker rmi $(REGISTRY):$(ENV) 2>/dev/null || true
	@echo "✅ Cleanup completed"

# Show logs (if running locally)
logs:
	@echo "📋 Following application logs (Ctrl+C to stop):"
	@docker logs -f $(IMAGE_NAME) 2>/dev/null || echo "❌ Container not running locally"

# Show deployment status in Kubernetes
status:
	@echo "📊 Jamie SRE Chatbot Status:"
	@echo "============================="
	@kubectl get pods -n chatbots -l app=jamie-sre-chatbot
	@echo ""
	@kubectl get deployment -n chatbots jamie-sre-chatbot
	@echo ""
	@kubectl get configmap -n chatbots jamie-sre-chatbot-config
	@echo ""
	@kubectl get sealedsecret -n chatbots jamie-sre-chatbot-secrets

# Open shell in running container
shell:
	@echo "🐚 Opening shell in Jamie SRE Chatbot container..."
	@kubectl exec -it -n chatbots deployment/jamie-sre-chatbot -- /bin/bash

# Run tests
test:
	@echo "🧪 Running tests..."
	@python -m pytest tests/ -v || echo "❌ No tests found or pytest not installed"

# Format Python code
format:
	@echo "🎨 Formatting Python code..."
	@python -m black src/ || echo "❌ Black not installed"
	@python -m isort src/ || echo "❌ isort not installed"
	@echo "✅ Code formatted"

# Lint Python code
lint:
	@echo "🔍 Linting Python code..."
	@python -m flake8 src/ || echo "❌ flake8 not installed"
	@python -m pylint src/ || echo "❌ pylint not installed"
	@echo "✅ Linting completed"