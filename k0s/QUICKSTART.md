# k0s Quick Start Guide

This guide will help you get your single-node k0s Kubernetes cluster up and running in minutes.

## Prerequisites Check

Before running the playbook, ensure:

```bash
# Check you're on Fedora 42
cat /etc/fedora-release

# Check available memory (should show ~4GB)
free -h

# Check CPU cores (should show 2)
nproc

# Check Ansible is installed
ansible --version
```

If Ansible is not installed:
```bash
sudo dnf install ansible -y
```

## Installation Steps

### 1. Navigate to the playbook directory

```bash
cd /path/to/k0s
```

### 2. Run the playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

The installation will take approximately 5-10 minutes depending on your internet connection.

### 3. Verify installation

Once complete, check the cluster status:

```bash
sudo k0s status
```

You should see output indicating k0s is running.

## Your First Commands

### Check cluster nodes

```bash
sudo k0s kubectl get nodes
```

Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
localhost  Ready    control-plane   1m    v1.29.1+k0s
```

### View all system pods

```bash
sudo k0s kubectl get pods -A
```

All pods should be in `Running` or `Completed` state.

### Setup kubectl access

For easier access without sudo, export the kubeconfig:

```bash
mkdir -p ~/.kube
sudo k0s kubeconfig admin > ~/.kube/config
chmod 600 ~/.kube/config
```

Now you can use `kubectl` directly (if installed):

```bash
kubectl get nodes
kubectl get pods -A
```

## Deploy Your First Application

### Create a simple nginx deployment

```bash
sudo k0s kubectl create deployment nginx --image=nginx:alpine
```

### Expose it as a service

```bash
sudo k0s kubectl expose deployment nginx --port=80 --type=NodePort
```

### Check the service

```bash
sudo k0s kubectl get svc nginx
```

Note the NodePort (will be in the 30000-32767 range).

### Access the application

```bash
curl http://localhost:<nodeport>
```

You should see the nginx welcome page HTML.

### Clean up

```bash
sudo k0s kubectl delete deployment nginx
sudo k0s kubectl delete service nginx
```

## Common Commands Reference

### Cluster Management

```bash
# Check cluster status
sudo k0s status

# View cluster info
sudo k0s kubectl cluster-info

# View node details
sudo k0s kubectl describe node localhost
```

### Pod Management

```bash
# List all pods in all namespaces
sudo k0s kubectl get pods -A

# List pods in specific namespace
sudo k0s kubectl get pods -n kube-system

# View pod logs
sudo k0s kubectl logs <pod-name> -n <namespace>

# Describe a pod (useful for troubleshooting)
sudo k0s kubectl describe pod <pod-name> -n <namespace>
```

### Service Management

```bash
# List all services
sudo k0s kubectl get svc -A

# Get service details
sudo k0s kubectl describe svc <service-name>
```

### Resource Monitoring

If metrics-server is enabled:

```bash
# View node resource usage
sudo k0s kubectl top nodes

# View pod resource usage
sudo k0s kubectl top pods -A
```

## Managing the k0s Service

### Check service status

```bash
sudo systemctl status k0scontroller
```

### Stop the cluster

```bash
sudo systemctl stop k0scontroller
```

### Start the cluster

```bash
sudo systemctl start k0scontroller
```

### Restart the cluster

```bash
sudo systemctl restart k0scontroller
```

### View service logs

```bash
sudo journalctl -u k0scontroller -f
```

## Troubleshooting

### Cluster not responding

1. Check the service is running:
```bash
sudo systemctl status k0scontroller
```

2. Check logs for errors:
```bash
sudo journalctl -u k0scontroller -n 50
```

3. Restart the service:
```bash
sudo systemctl restart k0scontroller
```

### Pods stuck in Pending state

Check if it's a resource issue:
```bash
sudo k0s kubectl describe pod <pod-name>
free -h
```

On a 4GB system, avoid running too many resource-intensive pods.

### Can't connect to API server

Verify the API server is listening:
```bash
sudo ss -tlnp | grep 6443
```

Check firewall:
```bash
sudo firewall-cmd --list-ports
```

### Memory pressure warnings

Monitor memory usage:
```bash
free -h
sudo k0s kubectl top nodes
sudo k0s kubectl top pods -A
```

Consider:
- Deleting unused pods/deployments
- Setting resource limits on workloads
- Not running too many concurrent applications

## Next Steps

### Install kubectl (optional)

For better CLI experience, install standalone kubectl:

```bash
sudo dnf install kubernetes-client -y
```

Then use it with the exported kubeconfig:
```bash
export KUBECONFIG=~/.kube/config
kubectl get nodes
```

### Deploy more applications

Try deploying:
- A simple web application
- A database (PostgreSQL, MySQL)
- Monitoring tools (Prometheus, Grafana)
- Service mesh (Istio, Linkerd)

### Learn Kubernetes

Resources to continue learning:
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [k0s Documentation](https://docs.k0sproject.io/)
- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/)

### Expand your cluster

When ready, you can add more nodes:
1. Modify the inventory to include additional machines
2. Generate join tokens with `sudo k0s token create --role worker`
3. Run the playbook on worker nodes

## Customizing Your Installation

To customize settings, create a `vars.yml` file:

```yaml
---
k0s_version: v1.29.1+k0s.0
k0s_enable_metrics_server: true
k0s_config:
  spec:
    network:
      podCIDR: 10.244.0.0/16
```

Then run:
```bash
ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
```

See `vars.example.yml` for all available options.

## Performance Tips for 4GB RAM Systems

1. **Limit concurrent workloads**: Don't run too many applications simultaneously
2. **Set resource limits**: Always define resource requests/limits in pod specs
3. **Monitor regularly**: Use `free -h` and `kubectl top` to watch resources
4. **Use alpine images**: Prefer smaller container images
5. **Disable unnecessary features**: Consider disabling metrics-server if not needed

## Re-running the Playbook

The playbook is idempotent. You can safely re-run it:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

This is useful for:
- Updating configuration
- Recovering from failures
- Applying new settings

## Getting Help

If you encounter issues:

1. Check the logs: `sudo journalctl -u k0scontroller -f`
2. Review the full README.md for detailed troubleshooting
3. Check k0s documentation: https://docs.k0sproject.io/
4. Review Kubernetes documentation: https://kubernetes.io/docs/

## Summary

You now have a working single-node Kubernetes cluster! Key things to remember:

- Use `sudo k0s kubectl` to interact with the cluster
- Or export kubeconfig to use standalone `kubectl`
- Manage the cluster with `systemctl` commands
- Monitor resources on your 4GB system
- The playbook can be re-run anytime

Happy learning! 🚀