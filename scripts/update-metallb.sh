#!/bin/bash
set -e

echo "Updating MetalLB deployment with fixed security contexts..."

# Delete the existing speaker daemonset and controller deployment
echo "Removing old MetalLB controller and speaker..."
kubectl delete deployment -n metallb-system controller --ignore-not-found=true
kubectl delete daemonset -n metallb-system speaker --ignore-not-found=true

# Wait a moment for cleanup
echo "Waiting for cleanup..."
sleep 3

# Reapply the configuration
echo "Applying updated configuration..."
cd /Users/ryan/code/infra/ksonnet
tk apply environments/mini-01

echo ""
echo "Waiting for pods to start..."
sleep 5

echo ""
echo "MetalLB Pod Status:"
kubectl get pods -n metallb-system

echo ""
echo "Traefik Service Status:"
kubectl get svc -n traefik traefik

echo ""
echo "Done! Wait a minute and check again if pods are still starting."
echo "Once the speaker pods are running, Traefik should get an EXTERNAL-IP."
