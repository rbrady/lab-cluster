# k0s Quick Reference Card

## 🚀 Installation Complete!

**Cluster**: mini-01.bobcat-ph.ts.net  
**Version**: k0s v1.34.1+k0s.0  
**Status**: ✅ Running

---

## 📋 Common Commands

### Using Makefile (Easiest)

```bash
# Check cluster status
make status

# Export kubeconfig to local machine
make kubeconfig

# View nodes (using local kubectl)
make kubectl-get-nodes

# View all pods (using local kubectl)
make kubectl-get-pods

# View all resources
make kubectl-get-all

# Re-run installation (idempotent)
make install

# Uninstall k0s
make uninstall
```

---

## 🔧 Using kubectl Locally

### Setup (one-time)

```bash
# Export kubeconfig
make kubeconfig

# Set environment variable
export KUBECONFIG=~/.kube/k0s-config

# Or add to your shell profile (~/.bashrc or ~/.zshrc)
echo 'export KUBECONFIG=~/.kube/k0s-config' >> ~/.bashrc
```

### Commands

```bash
# View cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes
kubectl get nodes -o wide

# Get all pods
kubectl get pods -A
kubectl get pods -n kube-system

# Get services
kubectl get svc -A

# Resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods -A

# Describe resources
kubectl describe node mini-01
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # follow

# Get all resources
kubectl get all -A
```

---

## 🖥️ Using SSH (Direct Access)

### Connect

```bash
ssh rbrady@mini-01.bobcat-ph.ts.net
```

### Commands on Server

```bash
# Check k0s status
sudo k0s status

# Use k0s kubectl
sudo k0s kubectl get nodes
sudo k0s kubectl get pods -A
sudo k0s kubectl cluster-info

# Service management
sudo systemctl status k0scontroller
sudo systemctl restart k0scontroller
sudo systemctl stop k0scontroller
sudo systemctl start k0scontroller

# View logs
sudo journalctl -u k0scontroller -f
sudo journalctl -u k0scontroller -n 100

# Resource monitoring
free -h
df -h
top
```

---

## 📦 Deploy Your First App

### Simple nginx Deployment

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:alpine

# Expose as service
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service details
kubectl get svc nginx

# Get the NodePort
kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Test (from server)
ssh rbrady@mini-01.bobcat-ph.ts.net "curl http://localhost:<nodeport>"

# Clean up
kubectl delete deployment nginx
kubectl delete service nginx
```

### From YAML

```bash
# Create a deployment file
cat <<EOF > nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Apply it
kubectl apply -f nginx-deployment.yaml

# Check status
kubectl get deployments
kubectl get pods

# Clean up
kubectl delete -f nginx-deployment.yaml
```

---

## 🔍 Troubleshooting

### Check Cluster Health

```bash
# Node status
kubectl get nodes

# All system pods
kubectl get pods -n kube-system

# Cluster info
kubectl cluster-info

# Component status (via server)
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo k0s status"
```

### Pod Issues

```bash
# Describe pod (shows events and errors)
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>

# Previous logs (if pod restarted)
kubectl logs <pod-name> -n <namespace> --previous

# Execute commands in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

### Resource Issues

```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -A

# Memory usage on server
ssh rbrady@mini-01.bobcat-ph.ts.net "free -h"

# Disk usage
ssh rbrady@mini-01.bobcat-ph.ts.net "df -h"
```

### Service Logs

```bash
# Via Ansible
make logs

# Via SSH
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo journalctl -u k0scontroller -f"
```

### Restart Cluster

```bash
# Via Ansible
ansible -i inventory.ini k0s_nodes -m systemd -a "name=k0scontroller state=restarted" --become

# Via SSH
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo systemctl restart k0scontroller"
```

---

## 📊 Monitoring

### Resource Usage

```bash
# Cluster-wide
kubectl top nodes
kubectl top pods -A

# Specific namespace
kubectl top pods -n kube-system

# Sort by memory
kubectl top pods -A --sort-by=memory

# Sort by CPU
kubectl top pods -A --sort-by=cpu
```

### Events

```bash
# All events
kubectl get events -A

# Sorted by time
kubectl get events -A --sort-by='.lastTimestamp'

# Watch events
kubectl get events -A --watch
```

---

## 🔐 Useful Configurations

### Bash Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Kubectl shortcuts
alias k='kubectl'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods -A'
alias kgs='kubectl get svc -A'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'

# k0s cluster
export KUBECONFIG=~/.kube/k0s-config

# SSH to cluster
alias k0s-ssh='ssh rbrady@mini-01.bobcat-ph.ts.net'
```

### kubectl Context

```bash
# View current context
kubectl config current-context

# View all contexts
kubectl config get-contexts

# Switch context (if you have multiple clusters)
kubectl config use-context <context-name>
```

---

## 📚 Learning Resources

### Official Documentation
- k0s: https://docs.k0sproject.io/
- Kubernetes: https://kubernetes.io/docs/

### Tutorials
- Kubernetes Basics: https://kubernetes.io/docs/tutorials/kubernetes-basics/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

### Local Files
- `README.md` - Complete documentation
- `QUICKSTART.md` - Quick start guide
- `INSTALLATION_SUCCESS.md` - Post-installation info
- `CHECKLIST.md` - Installation checklist

---

## ⚠️ Important Notes

### Resource Constraints
- **RAM**: 3.7GB available - avoid running too many apps simultaneously
- **Monitor**: Use `kubectl top` and `free -h` regularly
- **Set limits**: Always define resource requests/limits in pod specs

### Firewall Ports Open
- 6443/tcp - Kubernetes API
- 9443/tcp - k0s API
- 10250/tcp - Kubelet
- Additional ports for networking (see README.md)

### SELinux
- Currently in **permissive** mode for k0s compatibility

---

## 🆘 Getting Help

```bash
# kubectl help
kubectl --help
kubectl <command> --help

# k0s help
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo k0s --help"

# Makefile help
make help
```

---

## 🎯 Quick Tasks

### Deploy a test app
```bash
kubectl create deployment test --image=nginx:alpine
kubectl get pods
kubectl delete deployment test
```

### Check cluster health
```bash
kubectl get nodes
kubectl get pods -A
kubectl top nodes
```

### Export logs for troubleshooting
```bash
kubectl get events -A > events.log
kubectl get pods -A -o wide > pods.log
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo journalctl -u k0scontroller -n 500" > k0s.log
```

### Restart everything cleanly
```bash
ssh rbrady@mini-01.bobcat-ph.ts.net "sudo systemctl restart k0scontroller"
# Wait 2-3 minutes
kubectl get pods -A --watch
```

---

**Happy Kubernetes Learning! 🚀**

*Last updated: November 3, 2025*