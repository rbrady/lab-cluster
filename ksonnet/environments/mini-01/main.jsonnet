local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local myapp = import 'myapp.libsonnet';
local metallb = import 'metallb.libsonnet';
local traefik = import 'traefik.libsonnet';
local networkpolicy = import 'networkpolicy.libsonnet';
local localPathProvisioner = import 'local-path-provisioner.libsonnet';
local grafana = import 'grafana.libsonnet';
local prometheus = import 'prometheus/main.libsonnet';
local kubeStateMetrics = import 'kube-state-metrics.libsonnet';



{
  _config:: {
    namespace: 'default',
    cluster: 'mini-01',
    // MetalLB IP range using dedicated K8s network (192.168.10.0/24, VLAN 10)
    // Node is at 192.168.10.2, using 192.168.10.10-100 for LoadBalancer services
    metallbIPRange: '192.168.10.10-192.168.10.100',
  },

  // MetalLB for LoadBalancer support
  metallb: metallb.new()
    + metallb.withIPAddressPool('default-pool', self._config.metallbIPRange)
    + metallb.withL2Advertisement('default-l2', ['default-pool'])
    + {
      // Update L2Advertisement to use the VLAN interface
      ['l2Advertisement_default-l2']+: {
        spec+: {
          interfaces: ['enp3s0f0.10'],
        },
      },
    },

  // Traefik Ingress Controller
  traefik: traefik.new()
    + traefik.withReplicas(1)
    + traefik.withServiceType('LoadBalancer'),

  // Local Path Provisioner for persistent storage
  localPathProvisioner: localPathProvisioner.new(),

  // Grafana monitoring
  grafana: grafana.new(),
  // Prometheus for metrics collection
  prometheus: prometheus.new(),
  // Kube State Metrics for cluster state metrics
  kubeStateMetrics: kubeStateMetrics.new(),



  // Example nginx application
  nginx: myapp.new('nginx-demo', 'nginxdemos/hello:latest', replicas=2, port=80)
    + myapp.withServiceType('ClusterIP'),

  // NetworkPolicies to allow all pod-to-pod traffic
  // Required because kube-router runs with --run-firewall=true
  networkPolicyDefault: networkpolicy.allowAll('allow-all-default', 'default'),
  networkPolicyTraefik: networkpolicy.allowAll('allow-all-traefik', 'traefik'),
  networkPolicyMetalLB: networkpolicy.allowAll('allow-all-metallb', 'metallb-system'),
  networkPolicyLocalPath: networkpolicy.allowAll('allow-all-local-path', 'local-path-storage'),
  networkPolicyGrafana: networkpolicy.allowAll('allow-all-grafana', 'grafana'),
  networkPolicyMonitoring: networkpolicy.allowAll('allow-all-monitoring', 'monitoring'),
  networkPolicyKubeSystem: networkpolicy.allowAll('allow-all-kube-system', 'kube-system'),


}
