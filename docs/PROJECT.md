# Ksonnet Project Structure

This document provides an overview of the Tanka/Jsonnet project structure for deploying applications to the mini-01 Kubernetes cluster.

## Project Overview

This project uses [Tanka](https://tanka.dev/) and [Jsonnet](https://jsonnet.org/) to manage Kubernetes deployments in a declarative, code-based manner. Tanka provides a streamlined workflow for deploying applications, while Jsonnet enables powerful code reuse and abstraction.

## Directory Structure

```
ksonnet/
├── README.md                    # Comprehensive documentation
├── QUICKSTART.md                # 5-minute getting started guide
├── CHEATSHEET.md                # Quick reference for commands and patterns
├── PROJECT.md                   # This file - project structure overview
├── Makefile                     # Convenient command shortcuts
├── .gitignore                   # Git ignore patterns
│
├── jsonnetfile.json             # Dependency definitions
├── jsonnetfile.lock.json        # Locked dependency versions
│
├── environments/                # Tanka environments (one per cluster/context)
│   ├── default/                 # Default environment (unused)
│   │   ├── main.jsonnet         # Environment configuration
│   │   └── spec.json            # Environment specification
│   │
│   └── mini-01/                 # mini-01 cluster environment
│       ├── spec.json            # Cluster/namespace configuration
│       ├── main.jsonnet         # Main application definitions
│       ├── examples.jsonnet     # Example application patterns
│       └── apps/                # Application-specific configs
│           └── nginx-example.libsonnet
│
├── lib/                         # Reusable Jsonnet libraries
│   ├── k.libsonnet              # k8s-libsonnet import helper
│   ├── myapp.libsonnet          # Simple app deployment library
│   └── webapp.libsonnet         # Full-featured webapp library
│
└── vendor/                      # External dependencies (managed by jb)
    ├── github.com/
    │   ├── grafana/jsonnet-libs/
    │   └── jsonnet-libs/k8s-libsonnet/
    └── ...
```

## Key Files Explained

### Environment Configuration

**`environments/mini-01/spec.json`**
- Defines the target cluster API server and namespace
- Contains environment-specific settings
- Managed by `tk env` commands

**`environments/mini-01/main.jsonnet`**
- Main entry point for application definitions
- Imports and instantiates applications
- Contains environment-wide configuration in `_config` object

### Library Files

**`lib/k.libsonnet`**
- Helper file that imports the k8s-libsonnet library
- Provides the `k` object used throughout the project
- Example: `k.apps.v1.deployment.new()`

**`lib/myapp.libsonnet`**
- Simple, reusable library for basic deployments
- Creates Deployment + Service for a container
- Good starting point for simple applications

**`lib/webapp.libsonnet`**
- Full-featured library for web applications
- Includes ConfigMap, resource limits, probes, ingress
- Demonstrates advanced patterns and best practices

### Dependency Management

**`jsonnetfile.json`**
- Lists all external Jsonnet dependencies
- Defines versions and sources
- Edit manually or use `jb install` commands

**`jsonnetfile.lock.json`**
- Locks dependency versions for reproducibility
- Generated automatically by jsonnet-bundler
- Should be committed to version control

## Workflow

### 1. Define Your Application

Create or use a library in `lib/`:

```jsonnet
// lib/myservice.libsonnet
local k = import 'k.libsonnet';

{
  new(name, image):: {
    deployment: k.apps.v1.deployment.new(/* ... */),
    service: k.core.v1.service.new(/* ... */),
  },
}
```

### 2. Use in Environment

Add to `environments/mini-01/main.jsonnet`:

```jsonnet
local myservice = import 'myservice.libsonnet';

{
  myapp: myservice.new('myapp', 'myimage:v1.0.0'),
}
```

### 3. Preview Changes

```bash
make show ENV=environments/mini-01
# or
tk show environments/mini-01
```

### 4. Deploy

```bash
make apply ENV=environments/mini-01
# or
tk apply environments/mini-01
```

## Design Patterns

### 1. Configuration Pattern

Store configuration in `_config` objects:

```jsonnet
{
  _config:: {
    namespace: 'default',
    replicas: 3,
    image: 'myapp:v1.0.0',
  },
  
  // Use _config in resources
  deployment: /* ... uses this._config.replicas ... */,
}
```

### 2. Mixin Pattern

Create composable modifiers:

```jsonnet
{
  new(name, image):: { /* base config */ },
  
  withReplicas(n):: {
    deployment+: /* modify deployment */,
  },
  
  withIngress(host):: {
    ingress: /* add ingress */,
  },
}

// Usage: myapp.new('app', 'img') + myapp.withReplicas(5)
```

### 3. Multi-Environment Pattern

Define environment variations:

```jsonnet
local base = { /* shared config */ };

{
  dev: base { replicas: 1 },
  prod: base { replicas: 5 },
}
```

## Common Tasks

### Adding a New Application

1. Import or create a library
2. Add to `main.jsonnet`
3. Preview with `make show`
4. Deploy with `make apply`

### Updating an Application

1. Modify the configuration in `main.jsonnet`
2. Check diff with `make diff`
3. Apply with `make apply`

### Adding Dependencies

```bash
jb install github.com/grafana/jsonnet-libs/prometheus
```

Then import in your Jsonnet:
```jsonnet
local prometheus = import 'prometheus/prometheus.libsonnet';
```

### Creating a New Environment

```bash
tk env add environments/staging \
  --server=https://cluster.example.com:6443 \
  --namespace=staging
```

### Debugging

```bash
# Validate syntax
make validate

# Export to YAML files for inspection
make export

# Format code
make fmt
```

## Best Practices

1. **Keep Libraries Reusable**: Write generic libraries in `lib/`, environment-specific code in `environments/`

2. **Use _config Objects**: Centralize configuration for easy modification

3. **Test Locally First**: Always run `make show` and `make diff` before `make apply`

4. **Version Control Everything**: Commit both `jsonnetfile.json` and `jsonnetfile.lock.json`

5. **Apply Labels Consistently**: Use labels for organization and management

6. **Document Complex Logic**: Add comments to explain non-obvious code

7. **Keep Secrets Separate**: Don't commit secrets; use external secret management

8. **Start Simple**: Begin with simple deployments, add complexity as needed

## Environment Variables

The `mini-01` environment is configured for:
- **Cluster**: `mini-01.bobcat-ph.ts.net:6443`
- **Default Namespace**: `default`
- **K8s Version**: 1.29 (via k8s-libsonnet/1.29)

## Next Steps

- **New Users**: Start with [QUICKSTART.md](QUICKSTART.md)
- **Reference**: See [CHEATSHEET.md](CHEATSHEET.md) for common commands
- **Full Docs**: Read [README.md](README.md) for comprehensive documentation
- **Examples**: Check `environments/mini-01/examples.jsonnet` for patterns

## Resources

- **Tanka Documentation**: https://tanka.dev/
- **Jsonnet Language Guide**: https://jsonnet.org/learning/tutorial.html
- **k8s-libsonnet Reference**: https://jsonnet-libs.github.io/k8s-libsonnet/
- **Grafana Jsonnet Libraries**: https://github.com/grafana/jsonnet-libs

## Getting Help

1. Check the documentation in this directory
2. Review examples in `environments/mini-01/examples.jsonnet`
3. Consult the Tanka documentation at https://tanka.dev/
4. Use `tk show` to debug rendering issues
5. Use `jsonnet` CLI to test Jsonnet evaluation

## Maintenance

### Updating Dependencies

```bash
# Update all dependencies
make update

# Or manually
jb update
```

### Cleaning Up

```bash
# Remove generated files
make clean

# Remove deleted resources from cluster
make prune ENV=environments/mini-01
```

### Version Upgrades

To upgrade k8s-libsonnet version:
1. Edit `jsonnetfile.json` to change the version in the subdir
2. Run `jb update`
3. Test with `make show` and `make diff`
4. Update imports if API changes occurred