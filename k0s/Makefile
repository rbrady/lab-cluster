.PHONY: help install uninstall status logs verify clean check kubectl-get-nodes kubectl-get-pods kubectl-get-all

# Default target
help:
	@echo "k0s Ansible Playbook - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "  make install     - Install k0s single-node cluster"
	@echo "  make uninstall   - Remove k0s completely from the system"
	@echo "  make status      - Check k0s cluster status"
	@echo "  make logs        - View k0s service logs (follow mode)"
	@echo "  make verify      - Verify k0s installation and cluster health"
	@echo "  make check       - Run preflight checks only"
	@echo "  make clean       - Clean up ansible logs and temporary files"
	@echo ""
	@echo "Kubernetes Commands (remote via Ansible):"
	@echo "  make nodes       - Display cluster nodes"
	@echo "  make pods        - Display all pods in all namespaces"
	@echo "  make services    - Display all services"
	@echo "  make top-nodes   - Show node resource usage"
	@echo "  make top-pods    - Show pod resource usage"
	@echo ""
	@echo "Kubectl Commands (local with kubeconfig):"
	@echo "  make kubectl-get-nodes   - Get nodes with local kubectl"
	@echo "  make kubectl-get-pods    - Get all pods with local kubectl"
	@echo "  make kubectl-get-all     - Get all resources with local kubectl"
	@echo ""
	@echo "Advanced:"
	@echo "  make install-dry - Dry run of installation (check mode)"
	@echo "  make kubeconfig  - Export kubeconfig to ~/.kube/k0s-config"
	@echo ""

# Install k0s cluster
install:
	@echo "Installing k0s single-node cluster..."
	ansible-playbook -i inventory.ini playbook.yml

# Dry run of installation
install-dry:
	@echo "Running installation in check mode (no changes)..."
	ansible-playbook -i inventory.ini playbook.yml --check

# Uninstall k0s
uninstall:
	@echo "Uninstalling k0s cluster..."
	@read -p "Are you sure you want to uninstall k0s? All data will be lost. [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible-playbook -i inventory.ini uninstall.yml; \
	else \
		echo "Uninstall cancelled."; \
	fi

# Check cluster status
status:
	@echo "Checking k0s status..."
	@ansible-playbook -i inventory.ini status.yml

# View logs
logs:
	@echo "Viewing k0s logs (Ctrl+C to exit)..."
	@sudo journalctl -u k0scontroller -f

# Verify installation
verify:
	@echo "Verifying k0s installation..."
	@echo ""
	@echo "=== Service Status ==="
	@sudo systemctl status k0scontroller --no-pager || true
	@echo ""
	@echo "=== k0s Status ==="
	@sudo k0s status || true
	@echo ""
	@echo "=== Cluster Nodes ==="
	@sudo k0s kubectl get nodes || true
	@echo ""
	@echo "=== System Pods ==="
	@sudo k0s kubectl get pods -n kube-system || true

# Run preflight checks
check:
	@echo "Running preflight checks..."
	@echo ""
	@echo "=== System Information ==="
	@echo "OS: $$(cat /etc/fedora-release 2>/dev/null || echo 'Not Fedora')"
	@echo "Memory: $$(free -h | grep Mem | awk '{print $$2}')"
	@echo "CPUs: $$(nproc)"
	@echo "Architecture: $$(uname -m)"
	@echo ""
	@echo "=== Ansible Version ==="
	@ansible --version | head -n 1
	@echo ""
	@echo "=== Connectivity Check ==="
	@ansible -i inventory.ini k0s_nodes -m ping

# Display nodes (remote via Ansible)
nodes:
	@ansible -i inventory.ini k0s_nodes -m shell -a "/usr/local/bin/k0s kubectl get nodes -o wide" --become

# Display all pods (remote via Ansible)
pods:
	@ansible -i inventory.ini k0s_nodes -m shell -a "/usr/local/bin/k0s kubectl get pods -A -o wide" --become

# Display all services (remote via Ansible)
services:
	@ansible -i inventory.ini k0s_nodes -m shell -a "/usr/local/bin/k0s kubectl get svc -A" --become

# Show node resource usage (remote via Ansible)
top-nodes:
	@ansible -i inventory.ini k0s_nodes -m shell -a "/usr/local/bin/k0s kubectl top nodes" --become

# Show pod resource usage (remote via Ansible)
top-pods:
	@ansible -i inventory.ini k0s_nodes -m shell -a "/usr/local/bin/k0s kubectl top pods -A" --become

# Local kubectl commands (requires kubeconfig to be exported first)
kubectl-get-nodes:
	@if [ ! -f ~/.kube/k0s-config ]; then echo "Error: ~/.kube/k0s-config not found. Run 'make kubeconfig' first."; exit 1; fi
	@KUBECONFIG=~/.kube/k0s-config kubectl get nodes -o wide

kubectl-get-pods:
	@if [ ! -f ~/.kube/k0s-config ]; then echo "Error: ~/.kube/k0s-config not found. Run 'make kubeconfig' first."; exit 1; fi
	@KUBECONFIG=~/.kube/k0s-config kubectl get pods -A -o wide

kubectl-get-all:
	@if [ ! -f ~/.kube/k0s-config ]; then echo "Error: ~/.kube/k0s-config not found. Run 'make kubeconfig' first."; exit 1; fi
	@KUBECONFIG=~/.kube/k0s-config kubectl get all -A

# Export kubeconfig
kubeconfig:
	@echo "Exporting kubeconfig from remote server..."
	@ansible-playbook -i inventory.ini export-kubeconfig.yml
	@echo ""
	@echo "To use kubectl with this cluster:"
	@echo "  export KUBECONFIG=~/.kube/k0s-config"
	@echo "  kubectl get nodes"

# Clean up
clean:
	@echo "Cleaning up temporary files..."
	@rm -f ansible.log
	@rm -f *.retry
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -delete
	@echo "Cleanup complete."
