{
  // Node Exporter - exposes hardware and OS metrics
  scrapeConfig: {
    job_name: 'node-exporter',
    kubernetes_sd_configs: [
      {
        role: 'endpoints',
        namespaces: {
          names: ['kube-system'],
        },
      },
    ],
    relabel_configs: [
      {
        source_labels: ['__meta_kubernetes_service_label_app_kubernetes_io_name'],
        action: 'keep',
        regex: 'node-exporter',
      },
      {
        source_labels: ['__meta_kubernetes_endpoint_port_name'],
        action: 'keep',
        regex: 'metrics',
      },
      {
        source_labels: ['__meta_kubernetes_endpoint_address_target_kind', '__meta_kubernetes_endpoint_address_target_name'],
        separator: ';',
        regex: 'Node;(.*)',
        replacement: '${1}',
        target_label: 'node',
      },
      {
        source_labels: ['__meta_kubernetes_namespace'],
        action: 'replace',
        target_label: 'kubernetes_namespace',
      },
      {
        source_labels: ['__meta_kubernetes_service_name'],
        action: 'replace',
        target_label: 'kubernetes_name',
      },
    ],
  },
}
