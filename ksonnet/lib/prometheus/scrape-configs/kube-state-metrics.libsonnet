{
  // Kube State Metrics - exposes cluster state metrics
  scrapeConfig: {
    job_name: 'kube-state-metrics',
    kubernetes_sd_configs: [
      {
        role: 'service',
        namespaces: {
          names: ['kube-system'],
        },
      },
    ],
    relabel_configs: [
      {
        source_labels: ['__meta_kubernetes_service_label_app_kubernetes_io_name'],
        action: 'keep',
        regex: 'kube-state-metrics',
      },
      {
        source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_scrape'],
        action: 'keep',
        regex: true,
      },
      {
        source_labels: ['__meta_kubernetes_service_annotation_prometheus_io_port'],
        action: 'replace',
        target_label: '__address__',
        regex: '([^:]+)(?::\\d+)?;(\\d+)',
        replacement: '$1:$2',
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
