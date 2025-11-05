# k0s Installation Checklist

Use this checklist to ensure a smooth installation of your k0s single-node Kubernetes cluster.

## Pre-Installation Checklist

### System Requirements

- [ ] Running Fedora 42 (or compatible RHEL-based distribution)
- [ ] At least 4GB RAM available
- [ ] At least 2 CPU cores available
- [ ] At least 10GB free disk space
- [ ] x86_64 or aarch64 architecture
- [ ] Internet connectivity for downloading packages

### Verify System

```bash
# Check OS version
cat /etc/fedora-release

# Check memory (should show ~4GB)
free -h

# Check CPU cores (should show 2)
nproc

# Check disk space (should have >10GB free)
df -h /

# Check architecture (should be x86_64 or aarch64)
uname -m
```

### Software Prerequisites

- [ ] Ansible installed (version 2.9 or higher)
- [ ] Python 3 installed
- [ ] Root/sudo access available
- [ ] SSH access configured (if remote installation)

```bash
# Check Ansible version
ansible --version

# Check Python version
python3 --version

# Test sudo access
sudo echo "Sudo access OK"
```

### Install Ansible (if needed)

```bash
sudo dnf install ansible -y
```

## Installation Steps

### 1. Preparation

- [ ] Downloaded or cloned the k0s playbook repository
- [ ] Changed directory to the k0s playbook folder
- [ ] Reviewed README.md and QUICKSTART.md
- [ ] Customized variables (optional - create vars.yml if needed)

```bash
cd /path/to/k0s
ls -la
```

### 2. Inventory Configuration

- [ ] Verified inventory.ini is configured correctly
- [ ] For localhost: ensure it contains `localhost ansible_connection=local`
- [ ] For remote: updated with correct IP and credentials
- [ ] Tested connectivity

```bash
# Test inventory connectivity
ansible -i inventory.ini k0s_nodes -m ping
```

### 3. Pre-Flight Check

- [ ] Ran preflight check with Makefile

```bash
make check
```

Or manually:

```bash
# Check system info
ansible -i inventory.ini k0s_nodes -m setup
```

### 4. Run Installation

- [ ] Started installation playbook
- [ ] Monitored output for errors
- [ ] Waited for completion (5-10 minutes)

```bash
# Using Makefile (recommended)
make install

# Or using ansible-playbook directly
ansible-playbook -i inventory.ini playbook.yml

# With custom variables
ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
```

## Post-Installation Verification

### Check k0s Service

- [ ] k0s service is running
- [ ] k0s service is enabled

```bash
sudo systemctl status k0scontroller
```

### Verify Cluster

- [ ] Cluster status shows "running"
- [ ] Node is in "Ready" state
- [ ] System pods are running

```bash
# Check cluster status
sudo k0s status

# Check nodes
sudo k0s kubectl get nodes

# Check all pods
sudo k0s kubectl get pods -A
```

### API Server Health

- [ ] API server is responding
- [ ] Can retrieve cluster info

```bash
# Test API health
sudo k0s kubectl get --raw /healthz

# Get cluster info
sudo k0s kubectl cluster-info
```

### Kubeconfig Export

- [ ] Created ~/.kube directory
- [ ] Exported kubeconfig
- [ ] Set correct permissions

```bash
# Export kubeconfig
make kubeconfig

# Or manually
mkdir -p ~/.kube
sudo k0s kubeconfig admin > ~/.kube/config
chmod 600 ~/.kube/config
```

## First Application Deployment

### Deploy Test Application

- [ ] Created nginx deployment
- [ ] Exposed service
- [ ] Verified service is accessible

```bash
# Create deployment
sudo k0s kubectl create deployment nginx --image=nginx:alpine

# Expose service
sudo k0s kubectl expose deployment nginx --port=80 --type=NodePort

# Get service info
sudo k0s kubectl get svc nginx

# Test access (use the NodePort from above)
curl http://localhost:<nodeport>
```

### Cleanup Test Application

- [ ] Deleted test deployment
- [ ] Deleted test service

```bash
sudo k0s kubectl delete deployment nginx
sudo k0s kubectl delete service nginx
```

## Monitoring and Maintenance

### Regular Checks

- [ ] Set up monitoring for resource usage
- [ ] Configured log rotation
- [ ] Documented cluster configuration

```bash
# Check resource usage
free -h
sudo k0s kubectl top nodes
sudo k0s kubectl top pods -A

# View logs
sudo journalctl -u k0scontroller -n 50
```

### Backup Plan

- [ ] Documented backup procedure
- [ ] Know how to backup etcd data
- [ ] Saved kubeconfig files

Important directories to backup:
- `/etc/k0s/k0s.yaml` - Configuration
- `/var/lib/k0s/` - Data directory (includes etcd)

## Troubleshooting Reference

If you encounter issues, check:

- [ ] Service logs: `sudo journalctl -u k0scontroller -f`
- [ ] System resources: `free -h` and `top`
- [ ] Firewall rules: `sudo firewall-cmd --list-all`
- [ ] SELinux status: `getenforce`
- [ ] Network connectivity: `ping 8.8.8.8`
- [ ] Pod status: `sudo k0s kubectl describe pod <pod-name>`

## Optional Enhancements

### Additional Tools

- [ ] Install kubectl standalone: `sudo dnf install kubernetes-client`
- [ ] Install helm: `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`
- [ ] Install k9s (terminal UI): Visit https://k9scli.io/

### Learning Resources

- [ ] Bookmarked Kubernetes documentation
- [ ] Bookmarked k0s documentation
- [ ] Joined Kubernetes community forums
- [ ] Set learning goals for cluster usage

### Documentation

- [ ] Documented any custom configurations
- [ ] Created notes on deployment procedures
- [ ] Listed applications to deploy
- [ ] Documented troubleshooting steps encountered

## Success Criteria

Your installation is successful when:

- ✅ k0scontroller service is active and enabled
- ✅ `sudo k0s status` shows cluster is running
- ✅ `sudo k0s kubectl get nodes` shows node as Ready
- ✅ All system pods are Running
- ✅ You can deploy and access applications
- ✅ API server health check passes
- ✅ Kubeconfig is exported and working

## Next Steps

After successful installation:

1. [ ] Read through Kubernetes basics
2. [ ] Learn about pods, deployments, services
3. [ ] Experiment with different workloads
4. [ ] Practice with kubectl commands
5. [ ] Explore Helm charts
6. [ ] Set up monitoring (Prometheus/Grafana)
7. [ ] Try different networking options
8. [ ] Plan production-ready configurations

## Quick Command Reference

```bash
# Installation
make install              # Install k0s
make verify              # Verify installation
make status              # Check status

# Cluster Operations
make nodes               # View nodes
make pods                # View all pods
make services            # View all services
make top-nodes           # Resource usage - nodes
make top-pods            # Resource usage - pods

# Maintenance
make logs                # View logs (follow)
make kubeconfig          # Export kubeconfig
make clean               # Clean temp files

# Uninstall
make uninstall           # Remove k0s completely
```

## Notes

Add your own notes and observations here:

---

**Installation Date:** _______________

**k0s Version Installed:** _______________

**Issues Encountered:** _______________

**Custom Configurations:** _______________

---

## Completion

- [ ] All checks passed
- [ ] Cluster is operational
- [ ] Documentation reviewed
- [ ] Ready to use Kubernetes!

🎉 Congratulations! Your k0s single-node Kubernetes cluster is ready!