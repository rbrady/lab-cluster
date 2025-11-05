# k0s Single-Node Kubernetes Cluster with Ansible

This Ansible playbook automates the installation and configuration of a single-node k0s Kubernetes cluster on Fedora 42.

## Overview

k0s is a lightweight, CNCF-certified Kubernetes distribution that's easy to install and maintain. This playbook sets up a complete single-node cluster with both controller and worker components on the same machine.

## Prerequisites

- Fedora 42 (or similar RHEL-based distribution)
- Minimum 1GB RAM (2GB+ recommended)
- Minimum 1 CPU core (2+ recommended)
- Ansible 2.9 or higher installed
- Root/sudo access
- Internet connectivity for downloading k0s

### Installing Ansible on Fedora

```bash
sudo dnf install ansible -y
```

## Quick Start

1. Clone or download this repository to your Fedora machine

2. Run the playbook:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

3. After installation completes, interact with your cluster:
```bash
# Check cluster status
sudo k0s status

# View nodes
sudo k0s kubectl get nodes

# View all pods
sudo k0s kubectl get pods -A

# Export kubeconfig for regular kubectl usage
sudo k0s kubeconfig admin > ~/.kube/config
chmod 600 ~/.kube/config
```

## Configuration

### Default Settings

The playbook uses sensible defaults configured in `roles/k0s/defaults/main.yml`:

- **k0s version**: Latest stable release
- **Network provider**: kuberouter
- **Pod CIDR**: 10.244.0.0/16
- **Service CIDR**: 10.96.0.0/12
- **Metrics server**: Enabled
- **SELinux**: Set to permissive mode

### Customizing Installation

You can override default variables by creating a `vars.yml` file:

```yaml
---
k0s_version: "v1.29.1+k0s.0"  # Specific version
k0s_enable_metrics_server: true
k0s_selinux_permissive: true
k0s_configure_firewall: true
```

Then run with:
```bash
ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
```

### Memory and CPU Considerations

For a 4GB RAM system with dual-core processor:
- The cluster will run, but may be resource-constrained
- Avoid running many workloads simultaneously
- Consider limiting resource requests in pod specifications
- Monitor memory usage: `free -h` and `top`

## Playbook Structure

```
k0s/
├── playbook.yml              # Main playbook
├── inventory.ini             # Inventory file (localhost)
├── README.md                 # This file
├── roles/
│   └── k0s/
│       ├── defaults/
│       │   └── main.yml      # Default variables
│       ├── handlers/
│       │   └── main.yml      # Service handlers
│       ├── tasks/
│       │   ├── main.yml      # Main task orchestration
│       │   ├── preflight.yml # System checks
│       │   ├── prerequisites.yml # System prep
│       │   ├── install.yml   # k0s installation
│       │   ├── configure.yml # Configuration
│       │   ├── service.yml   # Service management
│       │   └── verify.yml    # Post-install verification
│       └── templates/
│           └── k0s.yaml.j2   # k0s config template
```

## What the Playbook Does

1. **Preflight Checks**
   - Validates system requirements (CPU, RAM, architecture)
   - Checks for systemd availability
   - Displays system information

2. **Prerequisites**
   - Installs required packages (curl, iptables, etc.)
   - Configures firewall rules for k0s ports
   - Sets SELinux to permissive mode
   - Enables IP forwarding and bridge networking
   - Loads required kernel modules

3. **Installation**
   - Downloads and installs k0s binary
   - Verifies installation integrity

4. **Configuration**
   - Generates k0s configuration from template
   - Validates configuration
   - Installs k0s as combined controller+worker

5. **Service Management**
   - Enables and starts k0s systemd service
   - Waits for API server to be ready

6. **Verification**
   - Waits for node to be ready
   - Displays cluster status and pods
   - Exports kubeconfig for easy access

## Common Operations

### Checking Cluster Status

```bash
sudo k0s status
```

### Managing the k0s Service

```bash
# Stop k0s
sudo systemctl stop k0scontroller

# Start k0s
sudo systemctl start k0scontroller

# Restart k0s
sudo systemctl restart k0scontroller

# Check service status
sudo systemctl status k0scontroller
```

### Using kubectl

```bash
# Using k0s kubectl
sudo k0s kubectl get nodes
sudo k0s kubectl get pods -A

# Using standalone kubectl (after exporting kubeconfig)
export KUBECONFIG=~/.kube/config
kubectl get nodes
kubectl get pods -A
```

### Deploying a Test Application

```bash
# Create a simple nginx deployment
sudo k0s kubectl create deployment nginx --image=nginx

# Expose it as a service
sudo k0s kubectl expose deployment nginx --port=80 --type=NodePort

# Check the service
sudo k0s kubectl get svc nginx
```

## Firewall Ports

The following ports are opened if firewalld is active:

| Port | Protocol | Purpose |
|------|----------|---------|
| 6443 | TCP | Kubernetes API Server |
| 8132 | TCP | Konnectivity Server |
| 9443 | TCP | k0s API |
| 10250 | TCP | Kubelet API |
| 10256 | TCP | Kube-proxy health check |
| 2380 | TCP | etcd peer communication |
| 6783 | TCP | Kube-router |
| 6784 | UDP | Kube-router VXLAN |

## Troubleshooting

### Cluster not starting

```bash
# Check k0s service logs
sudo journalctl -u k0scontroller -f

# Check k0s status
sudo k0s status

# Verify system requirements
free -h
nproc
```

### Pods not starting

```bash
# Check pod status
sudo k0s kubectl get pods -A

# Describe a problematic pod
sudo k0s kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
sudo k0s kubectl logs <pod-name> -n <namespace>
```

### Network issues

```bash
# Check if IP forwarding is enabled
sysctl net.ipv4.ip_forward

# Check if br_netfilter is loaded
lsmod | grep br_netfilter

# Verify firewall rules
sudo firewall-cmd --list-all
```

### Memory pressure

```bash
# Check memory usage
free -h
sudo k0s kubectl top nodes

# Check which pods are using memory
sudo k0s kubectl top pods -A
```

## Uninstalling k0s

To completely remove k0s:

```bash
# Stop and disable the service
sudo k0s stop
sudo systemctl disable k0scontroller

# Reset k0s (removes all data)
sudo k0s reset

# Remove the binary
sudo rm /usr/local/bin/k0s

# Remove configuration and data
sudo rm -rf /etc/k0s /var/lib/k0s
```

## Re-running the Playbook

The playbook is idempotent and can be safely re-run:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

This will:
- Skip steps that are already completed
- Update configuration if variables have changed
- Restart services only if necessary

## Remote Installation

To install k0s on a remote machine, update `inventory.ini`:

```ini
[k0s_nodes]
192.168.1.100 ansible_user=fedora ansible_become=yes

[k0s_nodes:vars]
ansible_python_interpreter=/usr/bin/python3
```

Then run:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

## Additional Resources

- [k0s Documentation](https://docs.k0sproject.io/)
- [k0s GitHub Repository](https://github.com/k0sproject/k0s)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

This playbook is provided as-is for educational and learning purposes.

## Contributing

Feel free to customize and extend this playbook for your specific needs!