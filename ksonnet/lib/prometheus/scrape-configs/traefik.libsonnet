{
  // Traefik ingress controller metrics
  scrapeConfig: {
    job_name: 'traefik',
    static_configs: [
      {
        targets: ['traefik-dashboard.traefik.svc.cluster.local:9000'],
      },
    ],
  },
}
