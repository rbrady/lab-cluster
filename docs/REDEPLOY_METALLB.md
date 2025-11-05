# Redeploy MetalLB - Final Fix

The MetalLB configuration has been fully fixed with:

**CRDs Added:**
- ✓ IPAddressPool
- ✓ L2Advertisement
- ✓ BGPPeer
- ✓ BGPAdvertisement
- ✓ BFDProfile
- ✓ Community

**RBAC Fixed:**
- ✓ Added `endpointslices` permission to speaker
- ✓ Added `pods` permission to speaker

**Scheduling Fixed:**
- ✓ Added tolerations for `control-plane` taint to controller

## Quick Redeploy

Run these commands to update your MetalLB deployment:

```bash
# 1. Delete the existing MetalLB pods
kubectl delete deployment -n metallb-system controller
kubectl delete daemonset -n metallb-system speaker

# 2. Apply the updated configuration with all CRDs
cd /Users/ryan/code/infra/ksonnet
tk apply environments/mini-01

# 3. Wait for pods to start (about 30 seconds)
sleep 30

# 4. Check the status
kubectl get pods -n metallb-system
kubectl get svc -n traefik traefik
```

## Expected Results

After redeployment, you should see:

```
NAME                          READY   STATUS    RESTARTS   AGE
controller-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
speaker-xxxxx                 1/1     Running   0          30s
```

And Traefik should have an EXTERNAL-IP:

```
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
traefik   LoadBalancer   10.104.58.19    192.168.1.240   80:31003/TCP,443:30824/TCP
```

## Troubleshooting

### If speaker is still crashing:

```bash
# Check logs
kubectl logs -n metallb-system -l component=speaker --tail=50

# Look for CRD-related errors - should be gone now
```

### If controller is still pending:

```bash
# Check events
kubectl describe pod -n metallb-system -l component=controller

# Look for scheduling or resource issues
```

### If Traefik doesn't get an IP:

1. Ensure speaker pods are running
2. Check speaker logs for errors
3. Verify IP pool range doesn't conflict with DHCP:
   ```bash
   kubectl get ipaddresspools -n metallb-system -o yaml
   ```

## What Changed

The updated `lib/metallb.libsonnet` now includes:

1. **All Required CRDs**: BGP-related and BFD CRDs that speaker needs
2. **Fixed Security Contexts**: Removed `readOnlyRootFilesystem` restrictions
3. **Proper Capabilities**: Added `NET_ADMIN` to speaker for network management

The configuration is now complete and should work properly!
