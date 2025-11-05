# Lab Cluster - Single Node k0s Kubernetes Learning Project

A learning project for deploying and managing a single-node Kubernetes cluster using k0s, Ansible, Tanka, and Jsonnet. This project demonstrates infrastructure-as-code practices, GitOps workflows, and cloud-native application deployment patterns.

## Overview

This repository contains the complete infrastructure setup for a home lab Kubernetes cluster running on a single Fedora 42 node. The project focuses on learning modern Kubernetes deployment and management tools, including:

- **Ansible**: Automated cluster provisioning and configuration on remote nodes
- **k0s**: Lightweight, CNCF-certified Kubernetes distribution
- **Tanka**: Flexible Kubernetes deployment tool using Jsonnet
- **Jsonnet**: Powerful configuration language for defining reusable Kubernetes resources

## Project Components

### Core Infrastructure

#### k0s Kubernetes Distribution
A lightweight, single-binary Kubernetes distribution that runs both controller and worker components on the same node. The cluster is configured with:
- kuberouter for networking
- Metrics server for resource monitoring
- Custom pod and service CIDR ranges
- SELinux in permissive mode for compatibility

#### MetalLB Load Balancer
Provides LoadBalancer service type support for bare-metal Kubernetes clusters. Configured with:
- Layer 2 mode for simple ARP-based load balancing
- Dedicated IP address pool (192.168.10.10-100) on VLAN 10
- Integration with the cluster's VLAN-tagged network interface

#### Traefik Ingress Controller
Modern reverse proxy and load balancer for routing external HTTP/HTTPS traffic to cluster services:
- Deployed as a LoadBalancer service
- Automatic service discovery
- Support for IngressRoute custom resources

#### Local Path Provisioner
Dynamic persistent volume provisioner that uses local storage:
- Automatically provisions PersistentVolumes from local directories
- Simple storage solution for single-node clusters
- No external storage dependencies required

#### Grafana Monitoring
Web-based observability platform for visualizing metrics and logs:
- Pre-configured dashboards for cluster monitoring
- Integration with Prometheus for metrics collection

#### Prometheus Metrics Collection
Time-series database and monitoring system:
- Collects metrics from cluster components and applications
- Service discovery for automatic target detection
- Foundation for alerting and observability

### Network Configuration

The cluster uses a dedicated VLAN network for Kubernetes services:
- **VLAN ID**: 10
- **Network**: 192.168.10.0/24
- **Node IP**: 192.168.10.2
- **MetalLB Pool**: 192.168.10.10-100
- **Interface**: enp3s0f0.10

Network policies are configured to allow all pod-to-pod traffic across namespaces, as kube-router runs with firewall mode enabled.

## Project Structure

```
lab-cluster/
├── k0s/                          # Ansible automation for k0s cluster
│   ├── playbook.yml              # Main Ansible playbook
│   ├── inventory.ini             # Ansible inventory (remote Linux node)
│   ├── ansible.cfg               # Ansible configuration
│   ├── roles/k0s/                # k0s installation role
│   │   ├── defaults/             # Default variables
│   │   ├── tasks/                # Task definitions
│   │   ├── handlers/             # Service handlers
│   │   └── templates/            # Jinja2 templates
│   ├── vars.example.yml          # Example variables file
│   └── README.md                 # Detailed k0s setup documentation
│
├── ksonnet/                      # Tanka/Jsonnet configurations
│   ├── environments/             # Deployment environments
│   │   └── mini-01/              # mini-01 cluster environment
│   │       ├── main.jsonnet      # Main application definitions
│   │       ├── spec.json         # Environment specification
│   │       └── apps/             # Application-specific configs
│   ├── lib/                      # Reusable Jsonnet libraries
│   │   ├── metallb.libsonnet     # MetalLB configuration
│   │   ├── traefik.libsonnet     # Traefik ingress setup
│   │   ├── grafana.libsonnet     # Grafana deployment
│   │   ├── prometheus.libsonnet  # Prometheus setup
│   │   ├── local-path-provisioner.libsonnet
│   │   ├── networkpolicy.libsonnet
│   │   ├── myapp.libsonnet       # Simple app template
│   │   └── webapp.libsonnet      # Full-featured app template
│   ├── vendor/                   # External dependencies (jb managed)
│   ├── jsonnetfile.json          # Dependency definitions
│   ├── Makefile                  # Convenient command shortcuts
│   └── README.md                 # Detailed Tanka documentation
│
├── docs/                         # Additional documentation
│   ├── QUICKSTART.md             # Quick start guide
│   ├── CHEATSHEET.md             # Command reference
│   ├── PROJECT.md                # Project structure details
│   └── TRAEFIK_METALLB.md        # Networking setup guide
│
├── scripts/                      # Utility scripts
│   ├── setup-mini-01.sh          # Cluster setup automation
│   └── update-metallb.sh         # MetalLB update script
│
├── LICENSE                       # Project license
└── README.md                     # This file
```

## Quick Start

### Prerequisites

**On your local machine (control node):**
- Ansible 2.9 or higher
- SSH access to the target Linux node
- Tanka, jsonnet-bundler (jb), and kubectl installed

**On the target node (mini-01):**
- Fedora 42 (or similar RHEL-based distribution)
- Minimum 2GB RAM, 2 CPU cores recommended
- SSH access with sudo privileges
- Internet connectivity

### Step 1: Install Tools on Your Local Machine

```bash
# Install Ansible
# On macOS:
brew install ansible

# On Fedora/RHEL:
sudo dnf install ansible -y

# On Ubuntu/Debian:
sudo apt install ansible -y

# Install Tanka
curl -fSL -o "/usr/local/bin/tk" \
  "https://github.com/grafana/tanka/releases/latest/download/tk-$(uname -s)-$(uname -m | sed 's/x86_64/amd64/')"
chmod +x /usr/local/bin/tk

# Install jsonnet-bundler
curl -fSL -o "/usr/local/bin/jb" \
  "https://github.com/jsonnet-bundler/jsonnet-bundler/releases/latest/download/jb-$(uname -s)-$(uname -m | sed 's/x86_64/amd64/')"
chmod +x /usr/local/bin/jb

# Install kubectl
# Follow instructions at: https://kubernetes.io/docs/tasks/tools/
```

### Step 2: Configure Ansible Inventory

Update `k0s/inventory.ini` with your target node information:

```ini
[k0s_nodes]
<cluster ip> ansible_user=your-username

[k0s_nodes:vars]
ansible_python_interpreter=/usr/bin/python3
```

Test SSH connectivity:

```bash
ssh your-username@<cluster-ip>
```

### Step 3: Deploy k0s to the Remote Node

From your local machine, run the Ansible playbook to provision k0s on the remote Linux node:

```bash
cd k0s
ansible-playbook -i inventory.ini playbook.yml
```

This playbook will:
1. Connect to the remote node via SSH
2. Install required system packages
3. Configure firewall and kernel parameters
4. Download and install k0s
5. Start the cluster as a combined controller+worker
6. Export kubeconfig to your local machine

**The playbook will automatically fetch the kubeconfig and save it locally.**

To manually export the kubeconfig after installation:

```bash
# From your local machine
ansible-playbook -i inventory.ini export-kubeconfig.yml

# Or manually via SSH
ssh <cluster-ip> "sudo k0s kubeconfig admin" > ~/.kube/k0s-config
chmod 600 ~/.kube/k0s-config
```

**Verify the cluster is running:**

```bash
export KUBECONFIG=~/.kube/k0s-config
kubectl get nodes
kubectl get pods -A
```

### Step 4: Install Tanka Dependencies

```bash
cd ksonnet
jb install
```

### Step 5: Deploy Applications to the Cluster

Deploy infrastructure components (MetalLB, Traefik, Grafana, Prometheus, etc.) using Tanka:

```bash
# Set kubeconfig
export KUBECONFIG=~/.kube/k0s-config

# Preview what will be deployed
tk show environments/mini-01

# Deploy all applications
tk apply environments/mini-01

# Verify deployments
kubectl get pods -A
kubectl get svc -A
```

### Step 6: Access Your Applications

```bash
# Get the LoadBalancer IPs assigned by MetalLB
kubectl get svc -A | grep LoadBalancer

# Example services:
# - Traefik: http://<traefik-lb-ip>
# - Grafana: http://<grafana-lb-ip> (default: admin/admin)
```

## Common Operations

### Check Cluster Status

```bash
export KUBECONFIG=~/.kube/k0s-config
kubectl get nodes
kubectl get pods -A
kubectl top nodes
```

### Deploy Changes with Tanka

```bash
cd ksonnet

# Preview changes
tk diff environments/mini-01

# Apply changes
tk apply environments/mini-01
```

### Update Application Configuration

Edit the relevant library in `ksonnet/lib/` or the environment configuration in `ksonnet/environments/mini-01/main.jsonnet`, then:

```bash
tk diff environments/mini-01   # Review changes
tk apply environments/mini-01  # Apply changes
```

### Add a New Application

1. Create or use a library in `ksonnet/lib/`
2. Add the application to `ksonnet/environments/mini-01/main.jsonnet`
3. Preview and deploy:

```bash
tk show environments/mini-01
tk apply environments/mini-01
```

### Manage k0s on the Remote Node

```bash
# SSH into the node
ssh <cluster-ip>

# Check k0s status
sudo k0s status
sudo systemctl status k0scontroller

# Restart k0s
sudo systemctl restart k0scontroller

# View logs
sudo journalctl -u k0scontroller -f
```

### Re-run Ansible Playbook

The playbook is idempotent and can be safely re-run:

```bash
cd k0s
ansible-playbook -i inventory.ini playbook.yml
```

## Recreating the Cluster from Scratch

### Uninstall and Reset k0s

```bash
# Run the uninstall playbook
cd k0s
ansible-playbook -i inventory.ini uninstall.yml

# Or manually via SSH
ssh <cluster-ip>
sudo k0s stop
sudo k0s reset
sudo systemctl disable k0scontroller
sudo rm -rf /etc/k0s /var/lib/k0s /usr/local/bin/k0s
```

### Reinstall k0s

```bash
cd k0s
ansible-playbook -i inventory.ini playbook.yml
```

### Redeploy Applications with Tanka

```bash
export KUBECONFIG=~/.kube/k0s-config
cd ksonnet
tk apply environments/mini-01
```

## Network Access

The cluster uses a VLAN-tagged network (VLAN 10) for service LoadBalancer IPs. Ensure your network infrastructure supports:
- VLAN tagging on the appropriate interface (enp3s0f0.10)
- Routing to the 192.168.10.0/24 network
- ARP traffic for MetalLB L2 announcements

## Learning Resources

### Documentation in This Repository
- `k0s/README.md` - Detailed Ansible and k0s setup guide
- `ksonnet/README.md` - Comprehensive Tanka/Jsonnet documentation
- `docs/QUICKSTART.md` - Fast-track guide for experienced users
- `docs/CHEATSHEET.md` - Quick reference for common commands
- `docs/PROJECT.md` - Detailed project structure explanation

### External Resources
- [k0s Documentation](https://docs.k0sproject.io/)
- [Tanka Documentation](https://tanka.dev/)
- [Jsonnet Tutorial](https://jsonnet.org/learning/tutorial.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Ansible Documentation](https://docs.ansible.com/)

## What You'll Learn

This project provides hands-on experience with:

1. **Infrastructure as Code**: Managing remote infrastructure with Ansible playbooks
2. **Remote Provisioning**: Deploying software to remote Linux nodes via SSH
3. **Kubernetes Administration**: Running and maintaining a Kubernetes cluster
4. **Configuration Management**: Using Jsonnet for reusable, composable configurations
5. **GitOps Workflows**: Declarative application deployment with Tanka
6. **Networking**: Understanding LoadBalancers, Ingress, VLANs, and network policies
7. **Monitoring**: Setting up observability with Prometheus and Grafana
8. **Storage**: Dynamic volume provisioning with Local Path Provisioner

## Troubleshooting

### Ansible Connection Issues

```bash
# Test SSH connectivity
ansible -i k0s/inventory.ini k0s_nodes -m ping

# Check SSH configuration
ssh -v <cluster-ip>ß
```

### Cluster Not Responding

```bash
# SSH to the node and check status
ssh <cluster-ip>ß
sudo systemctl status k0scontroller
sudo journalctl -u k0scontroller -f
```

### Tanka Connection Issues

```bash
# Verify kubeconfig is set
echo $KUBECONFIG

# Test kubectl connectivity
kubectl get nodes

# Check if server URL matches spec.json
kubectl config view --minify
```

### Pods Not Starting

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### MetalLB Not Assigning IPs

```bash
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
kubectl logs -n metallb-system -l app=metallb

# Check VLAN configuration on the node
ssh <cluster-ip>
ip addr show enp3s0f0.10
```

## Maintenance

### Update k0s

```bash
cd k0s
# Update k0s_version in roles/k0s/defaults/main.yml or create vars.yml
ansible-playbook -i inventory.ini playbook.yml
```

### Update Tanka Dependencies

```bash
cd ksonnet
jb update
tk apply environments/mini-01
```

### Backup Cluster Data

```bash
# Export all resources
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup k0s data from remote node
ssh <cluster-ip> "sudo tar -czf - /var/lib/k0s /etc/k0s" > k0s-backup.tar.gz
```

## Contributing

This is a personal learning project, but feel free to:
- Fork and adapt for your own use
- Submit issues or suggestions
- Share improvements or alternative approaches

## License

See the LICENSE file for details.

## Acknowledgments

This project uses and learns from:
- [k0s Project](https://k0sproject.io/)
- [Grafana Tanka](https://tanka.dev/)
- [Jsonnet](https://jsonnet.org/)
- [Ansible](https://www.ansible.com/)
- The Kubernetes community and ecosystem
