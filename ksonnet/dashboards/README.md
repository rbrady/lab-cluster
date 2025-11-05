# Grafana Dashboards and kube-state-metrics Setup

## Overview

This directory contains Grafana dashboards for monitoring your Kubernetes cluster and Traefik ingress controller.

## Dashboards

### 1. Kubernetes Cluster Overview
**File:** `kubernetes-cluster-overview.json`

High-level cluster health monitoring dashboard showing:
- Total nodes, pods, namespaces, and failed pods
- Node CPU and memory usage
- Network receive/transmit rates per node

### 2. Kubernetes Pod Resources
**File:** `kubernetes-pod-resources.json`

Detailed pod and container resource monitoring with:
- Filterable by namespace and pod name
- Container CPU and memory usage with statistics
- Pod network I/O metrics
- Pod status table with color-coded status

### 3. Traefik Metrics
**File:** `traefik-metrics.json`

Ingress controller monitoring dashboard featuring:
- Request rate, open connections, error rates (4xx/5xx)
- Requests per service
- Response status code distribution
- Request duration percentiles (p50, p95, p99)
- Bandwidth usage per service
- Backend server health status

## Setup Instructions

### 1. Deploy kube-state-metrics

kube-state-metrics has been added to your configuration and will be deployed to the `kube-system` namespace.

Apply the configuration:
```bash
cd /Users/ryan/code/infra/ksonnet/environments/mini-01
tk apply
```

Verify kube-state-metrics is running:
```bash
kubectl get pods -n kube-system -l app=kube-state-metrics
```

### 2. Configure Prometheus Data Source in Grafana

1. Access Grafana:
   ```bash
   kubectl port-forward -n grafana svc/grafana 3000:3000
   ```
   Visit: http://localhost:3000 (default credentials: admin/admin)

2. Add Prometheus data source:
   - Navigate to **Configuration** → **Data Sources** → **Add data source**
   - Select **Prometheus**
   - Configure:
     - **Name:** Prometheus
     - **URL:** `http://prometheus.monitoring.svc:9090`
     - **UID:** `prometheus` (important!)
   - Click **Save & test**

### 3. Import Dashboards

For each dashboard file:

1. In Grafana, navigate to **Dashboards** → **New** → **Import**
2. Click **Upload JSON file**
3. Select the dashboard file
4. Ensure the Prometheus data source is selected
5. Click **Import**

## Metrics Sources

The dashboards rely on metrics from:

- **kubelet**: Container metrics via cAdvisor endpoint
- **kube-state-metrics**: Cluster state metrics (pod status, node info, etc.)
- **node_exporter**: Node-level metrics (CPU, memory, network, disk)
- **Traefik**: Ingress controller metrics

## Prometheus Scrape Configuration

Prometheus is configured to scrape:
- **prometheus**: Self-monitoring
- **traefik**: Traefik metrics endpoint
- **kube-state-metrics**: Cluster state metrics (via service discovery)
- **kubernetes-apiservers**: API server metrics
- **kubernetes-nodes**: Kubelet metrics
- **kubernetes-cadvisor**: Container metrics
- **kubernetes-service-endpoints**: Services with `prometheus.io/scrape: "true"` annotation
- **kubernetes-pods**: Pods with `prometheus.io/scrape: "true"` annotation

## Troubleshooting

### Dashboard shows "No data"

1. **Check Prometheus targets:**
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```
   Visit: http://localhost:9090/targets
   
   Verify all targets are "UP"

2. **Check kube-state-metrics:**
   ```bash
   kubectl logs -n kube-system -l app=kube-state-metrics
   ```

3. **Verify metrics are being scraped:**
   In Prometheus UI, try queries like:
   ```promql
   up{job="kube-state-metrics"}
   kube_pod_info
   traefik_entrypoint_requests_total
   ```

### Traefik metrics not appearing

Ensure Traefik has received some traffic. Visit any service through your ingress to generate metrics.

### Missing node metrics

Some node metrics (like `node_memory_MemAvailable_bytes`) require the kubelet to be properly configured and accessible. The current setup scrapes kubelet metrics directly from nodes.

## Dashboard Customization

All dashboards are fully editable in Grafana. You can:
- Add/remove panels
- Adjust time ranges and refresh intervals
- Modify queries
- Change visualizations
- Add alerts

After customizing, export the updated JSON and save it back to this directory for version control.

## Adding Custom Scrape Configs

To add new services to Prometheus:

1. Create a new file in `lib/prometheus/scrape-configs/`
2. Import it in `lib/prometheus/main.libsonnet`
3. Add it to the `scrape_configs` array
4. Apply with `tk apply`

Example structure at `lib/prometheus/scrape-configs/`:
```
prometheus/
├── main.libsonnet
└── scrape-configs/
    ├── prometheus.libsonnet
    ├── traefik.libsonnet
    ├── kubernetes.libsonnet
    └── kube-state-metrics.libsonnet
```
