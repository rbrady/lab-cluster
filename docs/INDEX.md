# Tanka/Jsonnet Documentation Index

Welcome to the Tanka configuration for deploying applications to the **mini-01** Kubernetes cluster!

## 🚀 Quick Setup

**First time setup:**
```bash
# Run the setup script
./setup-mini-01.sh

# Set your environment (or add to ~/.bashrc or ~/.zshrc)
export KUBECONFIG=~/.kube/k0s-config
```

**Verify it works:**
```bash
kubectl get nodes
make show
make diff
```

See [QUICKSTART.md](QUICKSTART.md) for your first deployment!

## 📚 Documentation

Choose your starting point based on your needs:

### Getting Started
- **[QUICKSTART.md](QUICKSTART.md)** - Deploy your first app in 5 minutes ⚡
  - Prerequisites checklist
  - Step-by-step first deployment
  - Verify and test your deployment

### Reference Documentation
- **[README.md](README.md)** - Complete documentation 📖
  - Full feature documentation
  - Directory structure explanation
  - All commands and examples
  - Best practices guide
  - Troubleshooting section

- **[CHEATSHEET.md](CHEATSHEET.md)** - Quick command reference 🔍
  - Common Tanka commands
  - Jsonnet patterns and syntax
  - k8s-libsonnet examples
  - Standard library functions
  - Copy-paste ready snippets

- **[PROJECT.md](PROJECT.md)** - Project structure overview 🏗️
  - Directory layout explained
  - File purposes and relationships
  - Design patterns used
  - Workflow guide
  - Maintenance procedures

### Code Examples
- **[examples.jsonnet](environments/mini-01/examples.jsonnet)** - Working code examples 💻
  - 10+ ready-to-use patterns
  - Simple to complex deployments
  - StatefulSets, CronJobs, Jobs
  - Multi-environment patterns
  - Ingress configurations

### Libraries
Located in `lib/` directory:
- **[myapp.libsonnet](lib/myapp.libsonnet)** - Simple deployment library
- **[webapp.libsonnet](lib/webapp.libsonnet)** - Full-featured web app library

## 🚀 Quick Commands

```bash
# Preview what would be deployed
make show

# Show difference with cluster
make diff

# Deploy to cluster
make apply

# Get help
make help
```

## 🎯 Common Use Cases

| I want to... | Read this... |
|--------------|--------------|
| Deploy my first app quickly | [QUICKSTART.md](QUICKSTART.md) |
| Understand the full system | [README.md](README.md) |
| Find a specific command | [CHEATSHEET.md](CHEATSHEET.md) |
| See working examples | [examples.jsonnet](environments/mini-01/examples.jsonnet) |
| Learn the project structure | [PROJECT.md](PROJECT.md) |
| Deploy a simple web app | [lib/myapp.libsonnet](lib/myapp.libsonnet) + [QUICKSTART.md](QUICKSTART.md) |
| Create complex deployments | [lib/webapp.libsonnet](lib/webapp.libsonnet) + [examples.jsonnet](environments/mini-01/examples.jsonnet) |

## 📁 Project Structure

```
ksonnet/
├── INDEX.md                     # ← You are here
├── QUICKSTART.md                # Start here for new users
├── README.md                    # Full documentation
├── CHEATSHEET.md                # Command reference
├── PROJECT.md                   # Structure overview
├── Makefile                     # Convenient commands
│
├── environments/mini-01/        # Deployment configurations
│   ├── main.jsonnet             # Your apps go here
│   ├── examples.jsonnet         # Example patterns
│   └── spec.json                # Cluster config
│
└── lib/                         # Reusable libraries
    ├── myapp.libsonnet          # Simple deployments
    └── webapp.libsonnet         # Advanced deployments
```

## 🎓 Learning Path

1. **Complete Beginner**: Start with [QUICKSTART.md](QUICKSTART.md)
2. **Deployed First App**: Read [README.md](README.md) sections on creating applications
3. **Writing Custom Code**: Study [examples.jsonnet](environments/mini-01/examples.jsonnet)
4. **Daily Usage**: Bookmark [CHEATSHEET.md](CHEATSHEET.md)
5. **Advanced Patterns**: Review [lib/webapp.libsonnet](lib/webapp.libsonnet) implementation

## 🛠️ Tools Required

- **Tanka** (`tk`) - Install: https://tanka.dev/install
- **jsonnet-bundler** (`jb`) - Install: `go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest`
- **kubectl** - Install: https://kubernetes.io/docs/tasks/tools/

## 🌐 Cluster Information

- **Cluster**: mini-01:6443 (Tailscale hostname)
- **Environment**: `environments/mini-01`
- **Default Namespace**: `default`
- **Kubernetes Version**: 1.29
- **Kubeconfig**: `~/.kube/k0s-config` (must be set via `export KUBECONFIG=~/.kube/k0s-config`)

## 🔗 External Resources

- [Tanka Official Docs](https://tanka.dev/)
- [Jsonnet Language Tutorial](https://jsonnet.org/learning/tutorial.html)
- [k8s-libsonnet Reference](https://jsonnet-libs.github.io/k8s-libsonnet/)
- [Grafana Jsonnet Libraries](https://github.com/grafana/jsonnet-libs)

## 💡 Quick Tips

- **Set KUBECONFIG first**: `export KUBECONFIG=~/.kube/k0s-config`
- Always run `make show` before `make apply`
- Use `make diff` to see what will change
- Store reusable code in `lib/`
- Keep environment-specific config in `environments/mini-01/main.jsonnet`
- Check [examples.jsonnet](environments/mini-01/examples.jsonnet) when stuck

## ⚠️ Important Notes

The cluster certificate is only valid for the hostname `mini-01`, not the full FQDN or IP address. 
The setup script automatically configures your kubeconfig to use `https://mini-01:6443`.

---

**Need help?** 
1. Run `./setup-mini-01.sh` to verify your environment
2. Start with [QUICKSTART.md](QUICKSTART.md) 
3. Run `make help` for available commands
