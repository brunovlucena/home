.PHONY: help secret-argocd pf-argocd bootstrap-flux-dev bootstrap-flux-prd flux-status flux-logs init-dev init-prd up-dev up-prd destroy-dev destroy-prd clean logs-dev logs-prd status-dev status-prd setup-env flux-refresh flux-refresh-bruno flagger-status flagger-logs promote-canary rollback-canary istio-status istio-logs istio-proxy-status

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

# =============================================================================
# Flagger Progressive Delivery Operations
# =============================================================================

flagger-status: ## Check Flagger canary deployment status
	@echo "🔍 Checking Flagger canary status..."
	@echo "📊 Canary deployments:"
	kubectl get canaries --all-namespaces
	@echo ""
	@echo "📈 Canary analysis:"
	kubectl get canaries -n bruno -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,PROGRESS:.status.canaryWeight,ANALYSIS:.status.conditions[?(@.type=='Promoted')].status"
	@echo ""
	@echo "🚦 Traffic routing:"
	kubectl get virtualservice -n bruno -o custom-columns="NAME:.metadata.name,HOSTS:.spec.hosts[0],GATEWAYS:.spec.gateways[0]"

flagger-logs: ## View Flagger controller logs
	@echo "📋 Viewing Flagger controller logs..."
	kubectl logs -n flagger-system -l app=flagger -f

promote-canary: ## Manually promote canary deployment
	@echo "🚀 Promoting canary deployment..."
	@read -p "Enter canary name (default: bruno-site): " canary_name; \
	canary_name=$${canary_name:-bruno-site}; \
	read -p "Enter namespace (default: bruno): " namespace; \
	namespace=$${namespace:-bruno}; \
	kubectl -n $$namespace patch canary $$canary_name --type='merge' -p='{"spec":{"analysis":{"runCount":1}}}'
	@echo "✅ Canary promotion triggered"

rollback-canary: ## Manually rollback canary deployment
	@echo "🔄 Rolling back canary deployment..."
	@read -p "Enter canary name (default: bruno-site): " canary_name; \
	canary_name=$${canary_name:-bruno-site}; \
	read -p "Enter namespace (default: bruno): " namespace; \
	namespace=$${namespace:-bruno}; \
	kubectl -n $$namespace patch canary $$canary_name --type='merge' -p='{"spec":{"analysis":{"runCount":0}}}'
	@echo "✅ Canary rollback triggered"

# =============================================================================
# Blue/Green Deployment Utilities
# =============================================================================

deploy-blue-green: ## Deploy new version with blue/green strategy
	@echo "🔄 Starting blue/green deployment..."
	@read -p "Enter new image tag: " image_tag; \
	@read -p "Enter deployment name (default: bruno-site): " deployment_name; \
	deployment_name=$${deployment_name:-bruno-site}; \
	@read -p "Enter namespace (default: bruno): " namespace; \
	namespace=$${namespace:-bruno}; \
	kubectl set image deployment/$$deployment_name $$deployment_name=ghcr.io/brunovlucena/$$deployment_name:$$image_tag -n $$namespace
	@echo "✅ Blue/green deployment initiated"
	@echo "📊 Monitor progress with: make flagger-status"
	@echo "📋 View logs with: make flagger-logs"

test-canary: ## Run load test against canary deployment
	@echo "🧪 Running load test against canary..."
	@read -p "Enter canary name (default: bruno-site): " canary_name; \
	canary_name=$${canary_name:-bruno-site}; \
	@read -p "Enter namespace (default: bruno): " namespace; \
	namespace=$${namespace:-bruno}; \
	kubectl -n $$namespace exec deploy/k6-operator -- k6 run --out influxdb=http://prometheus-operated.prometheus.svc:9090 /scripts/load-test.js
	@echo "✅ Load test completed"

# =============================================================================
# Istio Service Mesh Operations
# =============================================================================

istio-status: ## Check Istio service mesh status
	@echo "🔍 Checking Istio service mesh status..."
	@echo "📊 Istio components:"
	kubectl get pods -n istio-system
	@echo ""
	@echo "🚦 Gateways:"
	kubectl get gateway --all-namespaces
	@echo ""
	@echo "🌐 Virtual Services:"
	kubectl get virtualservice --all-namespaces
	@echo ""
	@echo "🎯 Destination Rules:"
	kubectl get destinationrule --all-namespaces

istio-logs: ## View Istio control plane logs
	@echo "📋 Viewing Istio control plane logs..."
	kubectl logs -n istio-system -l app=istiod -f

istio-proxy-status: ## Check Istio proxy status for all pods
	@echo "🔍 Checking Istio proxy status..."
	kubectl exec -n istio-system deploy/istiod -- istioctl proxy-status
	@echo ""
	@echo "📊 Proxy configuration:"
	kubectl exec -n istio-system deploy/istiod -- istioctl analyze

# =============================================================================
# Service Mesh Traffic Management
# =============================================================================

traffic-split: ## Configure traffic splitting between blue/green environments
	@echo "🔄 Configuring traffic splitting..."
	@read -p "Enter blue weight (0-100, default: 100): " blue_weight; \
	blue_weight=$${blue_weight:-100}; \
	@read -p "Enter green weight (0-100, default: 0): " green_weight; \
	green_weight=$${green_weight:-0}; \
	kubectl patch virtualservice bruno-site-vs -n bruno --type='merge' -p="{\"spec\":{\"http\":[{\"route\":[{\"weight\":$$blue_weight},{\"weight\":$$green_weight}]}]}}"
	@echo "✅ Traffic splitting configured: Blue=$$blue_weight%, Green=$$green_weight%"

enable-mtls: ## Enable mTLS for service-to-service communication
	@echo "🔐 Enabling mTLS for service mesh..."
	kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
	EOF
	@echo "✅ mTLS enabled for all services in the mesh"

disable-mtls: ## Disable mTLS for service-to-service communication
	@echo "🔓 Disabling mTLS for service mesh..."
	kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: PERMISSIVE
	EOF
	@echo "✅ mTLS disabled (permissive mode)"

# =============================================================================
# GitHub Actions Runner Operations
# =============================================================================

github-runner-status: ## Check GitHub Actions runner status
	@echo "🏃‍♂️ Checking GitHub Actions runner status..."
	@echo "📊 Runner controller:"
	kubectl get pods -n github-actions-runner
	@echo ""
	@echo "🏃‍♂️ Active runners:"
	kubectl get runners -n github-actions-runner
	@echo ""
	@echo "📈 Runner deployment:"
	kubectl get runnerdeployment -n github-actions-runner

github-runner-logs: ## View GitHub Actions runner logs
	@echo "📋 Viewing GitHub Actions runner logs..."
	kubectl logs -n github-actions-runner -l app.kubernetes.io/name=github-actions-runner -f

github-runner-controller-logs: ## View GitHub Actions runner controller logs
	@echo "📋 Viewing GitHub Actions runner controller logs..."
	kubectl logs -n github-actions-runner -l app.kubernetes.io/name=actions-runner-controller -f

github-runner-scale: ## Scale GitHub Actions runners
	@echo "🔄 Scaling GitHub Actions runners..."
	@read -p "Enter number of replicas (default: 2): " replicas; \
	replicas=$${replicas:-2}; \
	kubectl scale runnerdeployment github-actions-runner-deployment -n github-actions-runner --replicas=$$replicas
	@echo "✅ Runner scaling completed"

github-runner-setup: ## Setup GitHub Actions runner secrets
	@echo "🔐 Setting up GitHub Actions runner secrets..."
	cd flux/clusters/studio/infrastructure/github-actions-runner && \
	chmod +x create-secrets.sh && \
	./create-secrets.sh
	@echo "✅ GitHub Actions runner setup completed"

github-runner-restart: ## Restart all GitHub Actions runners
	@echo "🔄 Restarting GitHub Actions runners..."
	kubectl delete pods -n github-actions-runner -l app.kubernetes.io/name=github-actions-runner
	@echo "✅ GitHub Actions runners restarted"

github-runner-metrics: ## Show GitHub Actions runner metrics
	@echo "📊 GitHub Actions runner metrics..."
	kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/github-actions-runner/pods
	@echo ""
	@echo "📈 Resource usage:"
	kubectl top pods -n github-actions-runner
