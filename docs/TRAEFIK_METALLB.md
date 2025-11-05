# Traefik and MetalLB Configuration

This document describes the Traefik and MetalLB configuration added to the mini-01 cluster.

## Overview

Two new infrastructure components have been added to the ksonnet project:

1. **MetalLB** - Provides LoadBalancer support for bare-metal Kubernetes clusters
2. **Traefik** - Modern reverse proxy and ingress controller

## Files Added

### Libraries
- `lib/metallb.libsonnet` - MetalLB library for load balancer support
- `lib/traefik.libsonnet` - Traefik library for ingress controller

### Configuration
- `environments/mini-01/main.jsonnet` - Updated with MetalLB and Traefik configurations

## MetalLB Configuration

MetalLB is configured with:
- **Namespace**: `metallb-system`
- **Version**: v0.14.3
- **Mode**: Layer 2 (L2)
- **IP Address Pool**: `192.168.1.240-192.168.1.250` (configurable in main.jsonnet)

### Components Deployed
- **CRDs**: IPAddressPool and L2Advertisement custom resource definitions
- Controller Deployment (manages IP allocation)
- Speaker DaemonSet (announces IPs via ARP/NDP)
- RBAC roles and bindings
- IPAddressPool resource (defines IP ranges)
- L2Advertisement resource (configures L2 mode)

### Customization

To change the IP address range, edit `environments/mini-01/main.jsonnet`:

```jsonnet
{
  _config:: {
    // Adjust this range to match your local network
    metallbIPRange: '192.168.1.240-192.168.1.250',
  },
}
```

## Traefik Configuration

Traefik is configured with:
- **Namespace**: `traefik`
- **Version**: v2.11
- **Service Type**: LoadBalancer (will get an IP from MetalLB)
- **Replicas**: 1

### Components Deployed
- Traefik Deployment
- LoadBalancer Service (ports 80/443)
- Dashboard Service (port 9000, internal only)
- RBAC roles and bindings
- IngressClass (set as default)

### Entry Points
- **web**: Port 8000 (exposed as 80 via LoadBalancer)
- **websecure**: Port 8443 (exposed as 443 via LoadBalancer)
- **traefik**: Port 9000 (dashboard, internal only)

### Features Enabled
- API Dashboard (accessible internally)
- Access logs
- Kubernetes Ingress support
- Kubernetes CRD support (IngressRoute, etc.)

## Usage

### Deploy to Cluster

```bash
# Show what will be deployed
tk show environments/mini-01

# Export to YAML
tk export manifests environments/mini-01

# Apply to cluster
tk apply environments/mini-01
```

### Verify Installation

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check Traefik pods
kubectl get pods -n traefik

# Check LoadBalancer IP assignment
kubectl get svc -n traefik traefik

# Access Traefik dashboard (port-forward)
kubectl port-forward -n traefik svc/traefik-dashboard 9000:9000
# Then visit http://localhost:9000/dashboard/
```

### Using Traefik Ingress

Once Traefik is deployed, you can create Ingress resources to route traffic to your services:

```jsonnet
// Example: Add ingress to an existing service
myapp: myapp.new('my-app', 'nginx:alpine')
  + myapp.withServiceType('ClusterIP')
  + {
    ingress: k.networking.v1.ingress.new('my-app')
      + k.networking.v1.ingress.spec.withIngressClassName('traefik')
      + k.networking.v1.ingress.spec.withRules([
        k.networking.v1.ingressRule.withHost('myapp.example.com')
        + k.networking.v1.ingressRule.http.withPaths([
          k.networking.v1.httpIngressPath.withPath('/')
          + k.networking.v1.httpIngressPath.withPathType('Prefix')
          + k.networking.v1.httpIngressPath.backend.service.withName('my-app')
          + k.networking.v1.httpIngressPath.backend.service.port.withNumber(80),
        ]),
      ]),
  },
```

## Library Features

### MetalLB Library

```jsonnet
local metallb = import 'metallb.libsonnet';

// Create MetalLB with custom IP pool
metallb: metallb.new()
  + metallb.withIPAddressPool('pool-1', '192.168.1.100-192.168.1.110')
  + metallb.withIPAddressPool('pool-2', ['192.168.1.200/29'])
  + metallb.withL2Advertisement('l2-advert', ['pool-1', 'pool-2']),
```

### Traefik Library

```jsonnet
local traefik = import 'traefik.libsonnet';

// Customize Traefik
traefik: traefik.new()
  + traefik.withReplicas(2)
  + traefik.withServiceType('LoadBalancer')
  + traefik.withVersion('v2.11')
  + traefik.withDashboardIngress('traefik.example.com')
  + traefik.withHTTPSRedirect()
  + traefik.withLetsEncrypt('admin@example.com', staging=false),
```

## Troubleshooting

### MetalLB not assigning IPs
- Ensure IP range doesn't conflict with DHCP
- Check speaker pods are running on all nodes
- Verify L2Advertisement matches IPAddressPool names

### Traefik not receiving traffic
- Verify LoadBalancer service has EXTERNAL-IP
- Check Traefik logs: `kubectl logs -n traefik -l app=traefik`
- Ensure IngressClass is set correctly on Ingress resources

### Port conflicts
- Default ports: 80 (HTTP), 443 (HTTPS)
- Change if needed by modifying the Traefik deployment arguments

## Next Steps

1. **Configure DNS**: Point your domain(s) to the Traefik LoadBalancer IP
2. **Add TLS**: Use `withLetsEncrypt()` for automatic HTTPS certificates
3. **Create Ingresses**: Route traffic to your applications
4. **Monitor**: Access Traefik dashboard for metrics and routing info
