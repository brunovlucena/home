package main

import (
	"fmt"
	"os"

	"github.com/pulumi/pulumi-command/sdk/go/command/local"
	"github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes"
	"github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/kustomize"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		// Get stack configuration
		stack := ctx.Stack()

		// Stack-specific configurations
		var clusterName string
		var clusterConfigFile string

		switch stack {
		case "studio":
			clusterName = "studio"
			clusterConfigFile = "../flux/clusters/studio/kind.yaml"
		default:
			return fmt.Errorf("unsupported stack: %s. Use 'studio'", stack)
		}

		// Create Kind cluster using Pulumi command provider (with cleanup)
		cluster, err := local.NewCommand(ctx, fmt.Sprintf("create-kind-cluster-%s", clusterName), &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("kind delete cluster --name %s 2>/dev/null || true && kind create cluster --name %s --config %s && kind export kubeconfig --name %s", clusterName, clusterName, clusterConfigFile, clusterName)),
			Delete: pulumi.String(fmt.Sprintf("kind delete cluster --name %s 2>/dev/null || true", clusterName)),
		})
		if err != nil {
			return err
		}

		// Create Kubernetes provider using the Kind cluster
		k8sProvider, err := kubernetes.NewProvider(ctx, fmt.Sprintf("%s-provider", clusterName), &kubernetes.ProviderArgs{
			Kubeconfig: pulumi.String("~/.kube/config"),
			Context:    pulumi.String(fmt.Sprintf("kind-%s", clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{cluster}))
		if err != nil {
			return err
		}

		// Wait for cluster to be ready using a simple command
		waitForCluster, err := local.NewCommand(ctx, "wait-for-cluster", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("kubectl --context kind-%s wait --for=condition=Ready nodes --all --timeout=300s", clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{cluster}))
		if err != nil {
			return err
		}

		// Get GitHub token from environment variable
		githubToken := os.Getenv("GITHUB_TOKEN")
		if githubToken == "" {
			return fmt.Errorf("GITHUB_TOKEN environment variable is required")
		}

		// Get GitHub username from environment variable or use default
		githubUsername := os.Getenv("GITHUB_USERNAME")
		if githubUsername == "" {
			githubUsername = "brunovlucena"
		}

		// Install Flux using Pulumi command provider
		flux, err := local.NewCommand(ctx, "flux-bootstrap", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("flux bootstrap github --token=%s --owner=brunovlucena --repository=kamaji --branch=%s --path=flux/clusters/%s --personal", githubToken, stack, clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{waitForCluster}))
		if err != nil {
			return err
		}

		// Create the GitHub secret using kubectl
		createSecret, err := local.NewCommand(ctx, "create-github-secret", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("kubectl --context kind-%s create secret generic bruno-site-helm --namespace=flux-system --from-literal=username=%s --from-literal=password=%s", clusterName, githubUsername, githubToken)),
		}, pulumi.DependsOn([]pulumi.Resource{flux}))
		if err != nil {
			return err
		}

		// Deploy infrastructure components using Kustomize from actual YAML files
		infrastructureResources, err := kustomize.NewDirectory(ctx, "infrastructure-resources", kustomize.DirectoryArgs{
			Directory: pulumi.String(fmt.Sprintf("../flux/clusters/%s/infrastructure", clusterName)),
		}, pulumi.Provider(k8sProvider), pulumi.DependsOn([]pulumi.Resource{createSecret}))
		if err != nil {
			return err
		}

		// Update HelmRelease with GitHub token
		updateHelmRelease, err := local.NewCommand(ctx, "update-helmrelease", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("kubectl --context kind-%s patch helmrelease bruno-site -n bruno --type='merge' -p='{\"spec\":{\"values\":{\"global\":{\"githubToken\":\"%s\"}}}}'", clusterName, githubToken)),
		}, pulumi.DependsOn([]pulumi.Resource{infrastructureResources}))
		if err != nil {
			return err
		}

		// Export cluster information
		ctx.Export("clusterName", pulumi.String(clusterName))
		ctx.Export("certManagerDeployed", pulumi.String("deployed"))
		ctx.Export("fluxOperatorInstalled", pulumi.String("installed"))
		ctx.Export("fluxInstanceDeployed", pulumi.String("deployed"))
		ctx.Export("kamajiDeployed", pulumi.String("deployed"))
		ctx.Export("observabilityComponents", pulumi.String("deployed"))
		ctx.Export("infrastructureResources", infrastructureResources.Resources)
		ctx.Export("helmReleaseUpdated", updateHelmRelease.Stdout)

		return nil
	})
}
