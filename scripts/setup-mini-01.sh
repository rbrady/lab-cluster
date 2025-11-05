#!/bin/bash
set -e

echo "🚀 Setting up environment for mini-01 cluster"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubeconfig exists
KUBECONFIG_PATH="$HOME/.kube/k0s-config"
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo -e "${RED}❌ Error: Kubeconfig not found at $KUBECONFIG_PATH${NC}"
    echo "   Please ensure your k0s kubeconfig is located there."
    exit 1
fi

echo -e "${GREEN}✓${NC} Found kubeconfig at $KUBECONFIG_PATH"

# Backup kubeconfig if not already backed up
BACKUP_PATH="$KUBECONFIG_PATH.backup"
if [ ! -f "$BACKUP_PATH" ]; then
    echo "   Creating backup at $BACKUP_PATH"
    cp "$KUBECONFIG_PATH" "$BACKUP_PATH"
    echo -e "${GREEN}✓${NC} Backup created"
fi

# Check current server URL
CURRENT_SERVER=$(grep -oE 'server: https://[^[:space:]]+' "$KUBECONFIG_PATH" | head -1 | cut -d' ' -f2)
echo "   Current server: $CURRENT_SERVER"

# Update kubeconfig to use mini-01 hostname if needed
if [[ "$CURRENT_SERVER" != "https://mini-01:6443" ]]; then
    echo "   Updating server URL to https://mini-01:6443"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' 's|server: https://[^[:space:]]*:6443|server: https://mini-01:6443|g' "$KUBECONFIG_PATH"
    else
        # Linux
        sed -i 's|server: https://[^[:space:]]*:6443|server: https://mini-01:6443|g' "$KUBECONFIG_PATH"
    fi
    echo -e "${GREEN}✓${NC} Updated kubeconfig to use mini-01 hostname"
else
    echo -e "${GREEN}✓${NC} Kubeconfig already configured correctly"
fi

# Test connection
echo ""
echo "Testing connection to mini-01 cluster..."
export KUBECONFIG="$KUBECONFIG_PATH"

if kubectl get nodes &>/dev/null; then
    echo -e "${GREEN}✓${NC} Successfully connected to mini-01 cluster"
    echo ""
    kubectl get nodes
else
    echo -e "${RED}❌ Failed to connect to mini-01 cluster${NC}"
    echo "   Please check:"
    echo "   1. Your Tailscale connection is active"
    echo "   2. The mini-01 host is reachable"
    echo "   3. The k0s service is running on mini-01"
    exit 1
fi

# Check Tanka installation
echo ""
if command -v tk &>/dev/null; then
    echo -e "${GREEN}✓${NC} Tanka is installed ($(tk --version))"
else
    echo -e "${YELLOW}⚠${NC}  Tanka (tk) is not installed"
    echo "   Install from: https://tanka.dev/install"
fi

# Check jsonnet-bundler installation
if command -v jb &>/dev/null; then
    echo -e "${GREEN}✓${NC} jsonnet-bundler is installed"
else
    echo -e "${YELLOW}⚠${NC}  jsonnet-bundler (jb) is not installed"
    echo "   Install with: go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest"
fi

# Install dependencies if jb is available
if command -v jb &>/dev/null; then
    echo ""
    echo "Installing Jsonnet dependencies..."
    if jb install; then
        echo -e "${GREEN}✓${NC} Dependencies installed"
    else
        echo -e "${YELLOW}⚠${NC}  Failed to install dependencies (may already be installed)"
    fi
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Setup complete!${NC}"
echo "=========================================="
echo ""
echo "To use the mini-01 cluster, run:"
echo -e "${YELLOW}export KUBECONFIG=$KUBECONFIG_PATH${NC}"
echo ""
echo "Or add this to your ~/.bashrc or ~/.zshrc:"
echo -e "${YELLOW}export KUBECONFIG=\"$KUBECONFIG_PATH\"${NC}"
echo ""
echo "Quick commands:"
echo "  make show              # Preview manifests"
echo "  make diff              # Show differences with cluster"
echo "  make apply             # Deploy to cluster"
echo ""
echo "See QUICKSTART.md for a complete guide."
echo ""
