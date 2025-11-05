local k = import 'k.libsonnet';

{
  new(namespace='monitoring'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      name: 'prometheus',
      image: 'prom/prometheus:latest',
      port: 9090,
      storageSize: '10Gi',
      labels: {
        app: 'prometheus',
        component: 'monitoring',
      },
    },

    // Start by adding the namespace resource
    namespace: k.core.v1.namespace.new(this._config.namespace)
               + k.core.v1.namespace.metadata.withLabels(this._config.labels),
    // ConfigMap for Prometheus configuration
    configMap: k.core.v1.configMap.new(this._config.name)
               + k.core.v1.configMap.metadata.withNamespace(this._config.namespace)
               + k.core.v1.configMap.metadata.withLabels(this._config.labels)
               + k.core.v1.configMap.withData({
                 'prometheus.yml': std.manifestYamlDoc({
                   global: {
                     scrape_interval: '15s',
                     evaluation_interval: '15s',
                   },
                   scrape_configs: [
                     {
                       job_name: 'prometheus',
                       static_configs: [
                         {
                           targets: ['localhost:9090'],
                         },
                       ],
                     },
                     {
                       job_name: 'traefik',
                       static_configs: [
                         {
                           targets: ['traefik-dashboard.traefik.svc.cluster.local:9000'],
                         },
                       ],
                     },
                   ],
                 }),
               }),
    // PVC for Prometheus data
    persistentVolumeClaim: k.core.v1.persistentVolumeClaim.new(this._config.name + '-data')
                           + k.core.v1.persistentVolumeClaim.metadata.withNamespace(this._config.namespace)
                           + k.core.v1.persistentVolumeClaim.metadata.withLabels(this._config.labels)
                           + k.core.v1.persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce'])
                           + k.core.v1.persistentVolumeClaim.spec.withStorageClassName('local-path')
                           + k.core.v1.persistentVolumeClaim.spec.resources.withRequests({
                             storage: this._config.storageSize,
                           }),
    // Deployment
    deployment: k.apps.v1.deployment.new(
                  name=this._config.name,
                  replicas=1,
                  containers=[
                    k.core.v1.container.new('prometheus', this._config.image)
                    + k.core.v1.container.withPorts([
                      k.core.v1.containerPort.new(this._config.port),
                    ])
                    + k.core.v1.container.withArgs([
                      '--config.file=/etc/prometheus/prometheus.yml',
                      '--storage.tsdb.path=/prometheus',
                      '--web.console.libraries=/usr/share/prometheus/console_libraries',
                      '--web.console.templates=/usr/share/prometheus/consoles',
                    ])
                    + k.core.v1.container.withVolumeMounts([
                      k.core.v1.volumeMount.new('data', '/prometheus'),
                      k.core.v1.volumeMount.new('config', '/etc/prometheus'),
                    ]),
                  ],
                )
                + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
                + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.spec.withVolumes([
                  k.core.v1.volume.fromPersistentVolumeClaim('data', this._config.name + '-data'),
                  k.core.v1.volume.fromConfigMap('config', this._config.name),
                ])
                + k.apps.v1.deployment.spec.template.spec.withTolerations([
                  {
                    key: 'node-role.kubernetes.io/master',
                    effect: 'NoSchedule',
                    operator: 'Exists',
                  },
                  {
                    key: 'node-role.kubernetes.io/control-plane',
                    effect: 'NoSchedule',
                    operator: 'Exists',
                  },
                ]),
    // Service
    service: k.core.v1.service.new(
               name=this._config.name,
               selector=this._config.labels,
               ports=[
                 k.core.v1.servicePort.new(port=this._config.port, targetPort=this._config.port)
                 + k.core.v1.servicePort.withName('http'),
               ],
             )
             + k.core.v1.service.metadata.withNamespace(this._config.namespace)
             + k.core.v1.service.metadata.withLabels(this._config.labels)
             + k.core.v1.service.spec.withType('ClusterIP'),

  },
}
