package main

import (
	"fmt"

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
		case "homelab":
			clusterName = "homelab"
			clusterConfigFile = "../flux/clusters/homelab/kind.yaml"
		default:
			return fmt.Errorf("unsupported stack: %s. Use 'studio' or 'homelab'", stack)
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

		// Install Flux controllers only (without GitRepository creation)
		flux, err := local.NewCommand(ctx, "install-flux", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("flux install --context kind-%s", clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{waitForCluster}))
		if err != nil {
			return err
		}

		// Create namespaces first
		_, err = local.NewCommand(ctx, "create-namespace", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf(`kubectl --context kind-%s create namespace cloudflare-ddns --dry-run=client -o yaml | kubectl apply -f - && \
kubectl --context kind-%s create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -`,
				clusterName, clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{flux}))
		if err != nil {
			return err
		}

		// Install Linkerd before infrastructure deployment
		linkerdInstall, err := local.NewCommand(ctx, "linkerd-install", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("cd ../scripts && ./install-linkerd.sh %s", clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{flux}))
		if err != nil {
			return err
		}

		// Install Linkerd Viz
		linkerdViz, err := local.NewCommand(ctx, "linkerd-viz-install", &local.CommandArgs{
			Create: pulumi.String(fmt.Sprintf("cd ../scripts && ./install-linkerd-viz.sh %s", clusterName)),
		}, pulumi.DependsOn([]pulumi.Resource{linkerdInstall}))
		if err != nil {
			return err
		}

		// Deploy infrastructure components using Kustomize from actual YAML files
		infrastructureResources, err := kustomize.NewDirectory(ctx, "infrastructure-resources", kustomize.DirectoryArgs{
			Directory: pulumi.String(fmt.Sprintf("../flux/clusters/%s/infrastructure", clusterName)),
		}, pulumi.Provider(k8sProvider), pulumi.DependsOn([]pulumi.Resource{linkerdViz}))
		if err != nil {
			return err
		}

		// Export cluster information
		ctx.Export("clusterName", pulumi.String(clusterName))
		ctx.Export("fluxInstanceDeployed", pulumi.String("deployed"))
		ctx.Export("linkerdInstalled", pulumi.String("installed"))
		ctx.Export("linkerdVizInstalled", pulumi.String("installed"))
		ctx.Export("infrastructureResources", infrastructureResources.Resources)

		return nil
	})
}
