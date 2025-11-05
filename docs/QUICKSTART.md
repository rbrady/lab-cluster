# Quick Start Guide

Get your first application deployed to mini-01 in 5 minutes!

## Important: Set Your Kubeconfig

Before starting, make sure you're using the correct kubeconfig:

```bash
export KUBECONFIG=~/.kube/k0s-config
```

Add this to your `~/.bashrc` or `~/.zshrc` to make it permanent when working with mini-01.

## Step 1: Verify Prerequisites

```bash
# Set kubeconfig
export KUBECONFIG=~/.kube/k0s-config

# Check that you have the required tools
tk --version
jb --version
kubectl version --client
```

If any are missing, install them:
- **Tanka**: https://tanka.dev/install
- **jsonnet-bundler**: `go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest`
- **kubectl**: https://kubernetes.io/docs/tasks/tools/

## Step 2: Verify Cluster Access

Make sure you can connect to the mini-01 cluster:

```bash
kubectl cluster-info
kubectl get nodes
```

If you don't have access, configure your kubeconfig with the mini-01 cluster credentials.

## Step 3: Deploy Your First Application

We'll deploy a simple nginx demo application.

### Option A: Using the Makefile (Recommended)

```bash
# Preview what will be deployed (no changes made)
make show ENV=environments/mini-01

# Deploy it!
make apply ENV=environments/mini-01
```

### Option B: Using Tanka directly

```bash
# Preview
tk show environments/mini-01

# Deploy
tk apply environments/mini-01
```

**Note**: Make sure `KUBECONFIG=~/.kube/k0s-config` is set in your environment.

## Step 4: Enable the Example App

Currently, the environment is empty. Let's enable the nginx example:

Edit `environments/mini-01/main.jsonnet` and uncomment the example line:

```jsonnet
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local myapp = import 'myapp.libsonnet';

{
  _config:: {
    namespace: 'default',
    cluster: 'mini-01',
  },

  // Uncomment this line:
  myapp: myapp.new('nginx-example', 'nginxdemos/hello:latest'),
}
```

Or replace the entire file with this ready-to-go version:

```jsonnet
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local myapp = import 'myapp.libsonnet';

{
  _config:: {
    namespace: 'default',
    cluster: 'mini-01',
  },

  nginx: myapp.new('nginx-demo', 'nginxdemos/hello:latest', replicas=2)
    + myapp.withServiceType('ClusterIP'),
}
```

Now deploy:

```bash
make apply ENV=environments/mini-01
```

## Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -l app=nginx-demo

# Check service
kubectl get svc nginx-demo

# Port-forward to access locally
kubectl port-forward svc/nginx-demo 8080:80
```

Then open http://localhost:8080 in your browser!

## What's Next?

### Customize Your Application

Modify the deployment in `environments/mini-01/main.jsonnet`:

```jsonnet
{
  nginx: myapp.new('nginx-demo', 'nginxdemos/hello:latest')
    + myapp.withReplicas(3)  // Scale to 3 replicas
    + myapp.withServiceType('LoadBalancer')  // Expose via LoadBalancer
    + myapp.withEnv([  // Add environment variables
      k.core.v1.envVar.new('ENV', 'production'),
    ]),
}
```

Then apply:
```bash
make diff    # See what will change
make apply   # Apply the changes
```

### Create a New Application

1. Create a new library in `lib/` or use the existing `myapp.libsonnet`
2. Import and use it in `environments/mini-01/main.jsonnet`
3. Apply with `make apply`

### Add More Libraries

```bash
# Install a library (e.g., Prometheus)
jb install github.com/prometheus-operator/prometheus-operator/jsonnet/prometheus-operator

# Use it in your manifests
```

### Deploy to Different Namespaces

Create a new environment for a different namespace:

```bash
tk env add environments/mini-01-staging \
  --server=https://mini-01.bobcat-ph.ts.net:6443 \
  --namespace=staging
```

## Common Commands Cheat Sheet

```bash
# Show what would be deployed
make show

# Show diff against cluster
make diff

# Deploy/update
make apply

# Delete everything
make delete

# Export to YAML files
make export

# List environments
make list

# Update dependencies
make update
```

## Troubleshooting

### "no cluster that matches the apiServer was found"

Make sure you have the correct kubeconfig set:
```bash
export KUBECONFIG=~/.kube/k0s-config
```

Then verify the server URL is correct:
```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
# Should show: https://mini-01:6443
```

### Import errors

Install dependencies:
```bash
make install
```

### Want to see raw YAML?

```bash
make show-yaml
# or
make export  # Saves to output/ directory
```

## Learn More

- Full documentation: [README.md](README.md)
- Tanka docs: https://tanka.dev/
- Jsonnet tutorial: https://jsonnet.org/learning/tutorial.html
- k8s-libsonnet: https://github.com/jsonnet-libs/k8s-libsonnet