local k = import 'k.libsonnet';

{
  new(namespace='grafana'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      name: 'grafana',
      image: 'grafana/grafana:latest',
      port: 3000,
      adminUser: 'admin',
      adminPassword: 'IndyAtlas2024!',
      storageSize: '10Gi',
      labels: {
        app: 'grafana',
        component: 'monitoring',
      },
    },

    // namespace
    namespace: k.core.v1.namespace.new(this._config.namespace)
               + k.core.v1.namespace.metadata.withLabels(this._config.labels),

    // PVC
    persistentVolumeClaim: k.core.v1.persistentVolumeClaim.new(this._config.name + '-data')
                           + k.core.v1.persistentVolumeClaim.metadata.withNamespace(this._config.namespace)
                           + k.core.v1.persistentVolumeClaim.metadata.withLabels(this._config.labels)
                           + k.core.v1.persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce'])
                           + k.core.v1.persistentVolumeClaim.spec.withStorageClassName('local-path')
                           + k.core.v1.persistentVolumeClaim.spec.resources.withRequests({
                             storage: this._config.storageSize,
                           }),

    // Service
    service: k.core.v1.service.new(
               name=this._config.name,
               selector=this._config.labels,
               ports=[
                 k.core.v1.servicePort.new(port=80, targetPort=this._config.port)
                 + k.core.v1.servicePort.withName('http'),
               ],
             )
             + k.core.v1.service.metadata.withNamespace(this._config.namespace)
             + k.core.v1.service.metadata.withLabels(this._config.labels)
             + k.core.v1.service.spec.withType('LoadBalancer')
             + k.core.v1.service.spec.withPorts([
               k.core.v1.servicePort.new(port=80, targetPort=this._config.port)
               + k.core.v1.servicePort.withName('http'),
             ]),

    // Deployment
    deployment: k.apps.v1.deployment.new(
                  name=this._config.name,
                  replicas=1,
                  containers=[
                    k.core.v1.container.new('grafana', this._config.image)
                    + k.core.v1.container.withPorts([
                      k.core.v1.containerPort.new(this._config.port),
                    ])
                    + k.core.v1.container.withEnv([
                      k.core.v1.envVar.new('GF_SECURITY_ADMIN_USER', this._config.adminUser),
                      k.core.v1.envVar.new('GF_SECURITY_ADMIN_PASSWORD', this._config.adminPassword),
                    ])
                    + k.core.v1.container.withVolumeMounts([
                      k.core.v1.volumeMount.new('data', '/var/lib/grafana'),
                    ]),
                  ],
                )
                + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
                + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.spec.withVolumes([
                  k.core.v1.volume.fromPersistentVolumeClaim('data', this._config.name + '-data'),
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
  },
}
