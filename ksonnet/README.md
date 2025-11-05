# Tanka Configuration for mini-01 Cluster

This directory contains Jsonnet/Tanka configurations for deploying applications to the `mini-01.bobcat-ph.ts.net` Kubernetes cluster.

## Prerequisites

- [Tanka](https://tanka.dev/install) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured with access to the cluster
- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler) (jb) installed
- **KUBECONFIG**: Set to `~/.kube/k0s-config` for the mini-01 cluster
  ```bash
  export KUBECONFIG=~/.kube/k0s-config
  ```

## Directory Structure

```
ksonnet/
├── environments/          # Tanka environments (one per cluster/namespace)
│   ├── mini-01/          # mini-01 cluster environment
│   │   ├── main.jsonnet  # Main configuration file
│   │   └── spec.json     # Environment specification
│   └── default/          # Default environment (not used)
├── lib/                   # Reusable Jsonnet libraries
│   ├── myapp.libsonnet   # Example application library
│   └── k.libsonnet       # k8s-libsonnet import helper
├── vendor/               # External dependencies (managed by jsonnet-bundler)
├── jsonnetfile.json      # Dependency definitions
└── jsonnetfile.lock.json # Locked dependency versions
```

## Quick Start

### 1. Verify your kubeconfig

Make sure you have access to the mini-01 cluster:

```bash
export KUBECONFIG=~/.kube/k0s-config
kubectl config get-contexts
kubectl get nodes
```

You should see the `mini-01` node in the Ready state.

### 2. List environments

```bash
tk env list
```

### 3. Preview what would be deployed

```bash
tk show environments/mini-01
```

### 4. Deploy to the cluster

```bash
tk apply environments/mini-01
```

**Note**: Make sure `KUBECONFIG=~/.kube/k0s-config` is set in your environment, or prefix commands with it:
```bash
KUBECONFIG=~/.kube/k0s-config tk apply environments/mini-01
```

### 5. Show differences

```bash
tk diff environments/mini-01
```

## Creating a New Application

### Using the myapp library

Edit `environments/mini-01/main.jsonnet` and add your application:

```jsonnet
local myapp = import 'myapp.libsonnet';

{
  nginx: myapp.new('nginx', 'nginx:latest')
    + myapp.withReplicas(3)
    + myapp.withServiceType('LoadBalancer'),
}
```

### Creating a custom application

Create a new library in `lib/`:

```jsonnet
// lib/myservice.libsonnet
local k = import 'k.libsonnet';

{
  new(name, namespace='default'):: {
    deployment: k.apps.v1.deployment.new(
      name=name,
      replicas=1,
      containers=[
        k.core.v1.container.new('app', 'myimage:latest'),
      ],
    ),
  },
}
```

Then use it in your environment:

```jsonnet
local myservice = import 'myservice.libsonnet';

{
  app: myservice.new('my-app'),
}
```

## Managing Dependencies

### Add a new dependency

```bash
jb install github.com/grafana/jsonnet-libs/prometheus
```

### Update dependencies

```bash
jb update
```

## Useful Commands

### Show all resources in an environment
```bash
tk show environments/mini-01
```

### Deploy only specific resources
```bash
tk apply environments/mini-01 --target=deployment/nginx
```

### Delete resources
```bash
tk delete environments/mini-01
```

### Prune removed resources
First enable injection of labels in `spec.json`:
```json
"spec": {
  "injectLabels": true
}
```

Then use prune:
```bash
tk prune environments/mini-01
```

### Export to YAML files
```bash
tk export environments/mini-01 output-dir/
```

## Environment Configuration

The mini-01 environment is configured to deploy to:
- **Cluster**: `mini-01:6443` (Tailscale hostname)
- **Namespace**: `default` (can be changed in `spec.json`)
- **Kubeconfig**: `~/.kube/k0s-config` (set via `export KUBECONFIG=~/.kube/k0s-config`)

### Important: Hostname Configuration

The cluster certificate is valid for the hostname `mini-01`, not the full FQDN `mini-01.bobcat-ph.ts.net`. 
Your kubeconfig at `~/.kube/k0s-config` has been configured to use `https://mini-01:6443` as the server address.
This allows Tanka to work properly with the cluster's TLS certificate.

To change the target namespace, edit `environments/mini-01/spec.json`:

```json
{
  "spec": {
    "namespace": "my-namespace"
  }
}
```

## Best Practices

1. **Keep environments DRY**: Use the `lib/` directory for reusable components
2. **Use _config objects**: Define configuration at the top of your files
3. **Test locally first**: Always run `tk show` and `tk diff` before `tk apply`
4. **Version control**: Commit both `jsonnetfile.json` and `jsonnetfile.lock.json`
5. **Use labels**: Apply consistent labels for easy resource management

## Example: Deploy a Simple Web App

1. Create the application definition in `environments/mini-01/main.jsonnet`:

```jsonnet
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local myapp = import 'myapp.libsonnet';

{
  _config:: {
    namespace: 'default',
    cluster: 'mini-01',
  },

  webapp: myapp.new('webapp', 'nginxdemos/hello:latest', replicas=2)
    + myapp.withServiceType('ClusterIP'),
}
```

2. Preview the changes:
```bash
tk show environments/mini-01
```

3. Deploy:
```bash
tk apply environments/mini-01
```

4. Verify:
```bash
kubectl get pods,svc -l app=webapp
```

## Troubleshooting

### "no cluster that matches the apiServer was found"

Make sure you're using the correct kubeconfig:
```bash
export KUBECONFIG=~/.kube/k0s-config
tk apply environments/mini-01
```

If you still have issues, verify that your kubeconfig server URL matches the environment spec:
```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
# Should output: https://mini-01:6443
```

### TLS Certificate Errors

If you see certificate validation errors mentioning `mini-01.bobcat-ph.ts.net`, your kubeconfig 
is using the wrong hostname. The certificate is only valid for `mini-01`. Update your kubeconfig:
```bash
# Backup first
cp ~/.kube/k0s-config ~/.kube/k0s-config.backup

# Update to use mini-01 instead of IP or FQDN
sed -i.bak 's|https://[^:]*:6443|https://mini-01:6443|g' ~/.kube/k0s-config
```

### Import errors

Make sure dependencies are installed:
```bash
jb install
```

### View rendered Kubernetes manifests

```bash
tk show environments/mini-01 --format=yaml
```

## Resources

- [Tanka Documentation](https://tanka.dev/)
- [Jsonnet Language](https://jsonnet.org/)
- [k8s-libsonnet](https://github.com/jsonnet-libs/k8s-libsonnet)
- [Jsonnet Libraries](https://github.com/grafana/jsonnet-libs)