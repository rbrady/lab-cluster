# 🎉 k0s Installation Successful!

**Congratulations!** Your k0s single-node Kubernetes cluster has been successfully installed on `mini-01.bobcat-ph.ts.net`!

## Installation Summary

- **Host**: mini-01.bobcat-ph.ts.net
- **k0s Version**: v1.34.1+k0s.0
- **Kubernetes Version**: v1.34.1+k0s
- **Operating System**: Fedora Linux 42 (Server Edition)
- **Kernel**: 6.14.4-300.fc42.x86_64
- **Memory**: 3781 MB (3.7 GB)
- **CPUs**: 4 cores
- **Architecture**: x86_64
- **Container Runtime**: containerd 1.7.28

## Cluster Status

✅ **Service**: k0scontroller is active and running  
✅ **Node**: mini-01 is Ready  
✅ **Role**: control-plane with workloads enabled  
✅ **API Server**: Responding successfully  

### System Pods Status

The following system pods are running or starting:
- ✅ kube-proxy: Running
- 🔄 coredns: ContainerCreating (will be ready soon)
- 🔄 konnectivity-agent: ContainerCreating (will be ready soon)
- 🔄 kube-router: PodInitializing (will be ready soon)
- 🔄 metrics-server: ContainerCreating (will be ready soon)

*Note: Pods marked with 🔄 are still initializing, which is normal right after installation.*

## What Was Configured

### System Changes
- ✅ Firewall rules configured for Kubernetes ports
- ✅ SELinux set to permissive mode
- ✅ IP forwarding enabled
- ✅ Bridge netfilter module loaded
- ✅ Required system packages installed

### Network Configuration
- **API Server**: Bound to 100.69.220.52:6443
- **Pod Network**: 10.244.0.0/16
- **Service Network**: 10.96.0.0/12
- **Network Provider**: kuberouter

### Features Enabled
- ✅ Controller + Worker (single-node configuration)
- ✅ Metrics server (for resource monitoring)
- ✅ Helm chart repositories configured
- ✅ CoreDNS for cluster DNS

## How to Use Your Cluster

### From the Server (mini-01)

SSH into your server:
```bash
ssh rbrady@mini-01.bobcat-ph.ts.net
```

Then use k0s kubectl:
```bash
# Check cluster status
sudo k0s status

# View nodes
sudo k0s kubectl get nodes

# View all pods
sudo k0s kubectl get pods -A

# Get cluster info
sudo k0s kubectl cluster-info
```

### From Your Local Machine

Export the kubeconfig from the server:
```bash
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo k0s kubeconfig admin" > ~/.kube/k0s-config
chmod 600 ~/.kube/k0s-config
export KUBECONFIG=~/.kube/k0s-config
```

Then use kubectl locally:
```bash
kubectl get nodes
kubectl get pods -A
```

### Using Ansible (Recommended)

Check status:
```bash
ansible-playbook -i inventory.ini status.yml
```

Or use the Makefile:
```bash
make status
```

## Your First Application

Deploy a test application:
```bash
# SSH to the server
ssh rbrady@mini-01.bobcat-ph.ts.net

# Create a deployment
sudo k0s kubectl create deployment nginx --image=nginx:alpine

# Expose it as a service
sudo k0s kubectl expose deployment nginx --port=80 --type=NodePort

# Check the service
sudo k0s kubectl get svc nginx

# Get the NodePort
NODEPORT=$(sudo k0s kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')
echo "Access nginx at: http://localhost:$NODEPORT"

# Test it
curl http://localhost:$NODEPORT
```

Clean up:
```bash
sudo k0s kubectl delete deployment nginx
sudo k0s kubectl delete service nginx
```

## Monitoring Your Cluster

### Check Resource Usage

Once metrics-server is fully running:
```bash
# Node resources
sudo k0s kubectl top nodes

# Pod resources
sudo k0s kubectl top pods -A
```

### View Logs

Service logs:
```bash
sudo journalctl -u k0scontroller -f
```

Pod logs:
```bash
sudo k0s kubectl logs <pod-name> -n <namespace>
```

### Service Management

```bash
# Check status
sudo systemctl status k0scontroller

# Restart
sudo systemctl restart k0scontroller

# Stop
sudo systemctl stop k0scontroller

# Start
sudo systemctl start k0scontroller
```

## Important Notes

### Resource Considerations

Your system has 3.7GB RAM, which is adequate for learning but conservative:
- ⚠️ Avoid running too many resource-intensive applications simultaneously
- 💡 Always set resource limits on your deployments
- 📊 Monitor memory usage regularly with `free -h` and `kubectl top nodes`

### Firewall Ports Opened

The following ports are now open on your firewall:
- 6443/tcp - Kubernetes API
- 8132/tcp - Konnectivity
- 9443/tcp - k0s API
- 10250/tcp - Kubelet
- 10256/tcp - Kube-proxy health
- 2380/tcp - etcd peer
- 6783/tcp - Kube-router
- 6784/udp - Kube-router

### SELinux

SELinux has been set to **permissive** mode to ensure k0s functions correctly. For production use, consider creating proper SELinux policies.

## Next Steps

### 1. Wait for All Pods to be Ready

Give the cluster a few minutes for all system pods to fully start:
```bash
watch sudo k0s kubectl get pods -A
```

### 2. Explore Kubernetes

- Learn about pods, deployments, and services
- Try deploying different applications
- Experiment with ConfigMaps and Secrets
- Explore persistent volumes

### 3. Install Additional Tools

**kubectl** (standalone):
```bash
sudo dnf install kubernetes-client -y
```

**helm** (package manager):
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**k9s** (terminal UI):
Visit https://k9scli.io/ for installation instructions

### 4. Learn More

- [k0s Documentation](https://docs.k0sproject.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)

## Troubleshooting

If you encounter any issues:

1. **Check service logs**: `sudo journalctl -u k0scontroller -f`
2. **Check pod status**: `sudo k0s kubectl describe pod <pod-name> -n <namespace>`
3. **Verify resources**: `free -h` and `df -h`
4. **Check network**: `sudo k0s kubectl get pods -n kube-system`
5. **Restart if needed**: `sudo systemctl restart k0scontroller`

For detailed troubleshooting, see `README.md` and `QUICKSTART.md`.

## Maintenance

### Re-run the Playbook

The playbook is idempotent and safe to re-run:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### Update k0s

To update to a newer version, modify `vars.yml`:
```yaml
k0s_version: v1.35.0+k0s.0  # or whatever version you want
```

Then re-run the playbook.

### Backup Important Data

Regularly backup:
- `/etc/k0s/k0s.yaml` - Configuration
- `/var/lib/k0s/` - Data directory (includes etcd)

## Quick Reference

```bash
# Status checks
sudo k0s status
sudo systemctl status k0scontroller

# Cluster info
sudo k0s kubectl get nodes
sudo k0s kubectl get pods -A
sudo k0s kubectl cluster-info

# Resources
sudo k0s kubectl top nodes
sudo k0s kubectl top pods -A

# Logs
sudo journalctl -u k0scontroller -f
sudo k0s kubectl logs <pod> -n <namespace>

# Service management
sudo systemctl start|stop|restart k0scontroller
```

---

## 🚀 You're Ready!

Your Kubernetes learning environment is now set up and ready to use!

**Happy Learning!** 🎓

For more information, refer to:
- `README.md` - Complete documentation
- `QUICKSTART.md` - Quick start guide
- `PROJECT_STRUCTURE.md` - Project layout
- `CHECKLIST.md` - Installation checklist

---

*Installation completed on: November 3, 2025*
*Cluster name: k0s-single-node*
*Node name: mini-01*