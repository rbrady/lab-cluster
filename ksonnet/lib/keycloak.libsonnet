local k = import 'k.libsonnet';

{
  new(namespace='keycloak'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      name: 'keycloak',
      image: 'quay.io/keycloak/keycloak:latest',
      httpPort: 8080,
      httpsPort: 8443,
      adminUser: 'admin',
      adminPassword: 'admin!',
      storageSize: '5Gi',
      labels: {
        app: 'keycloak',
        component: 'identity',
      },
    },

    // namespace
    namespace: k.core.v1.namespace.new(this._config.namespace)
               + k.core.v1.namespace.metadata.withLabels(this._config.labels),

    // PVC for Keycloak data
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
                 k.core.v1.servicePort.new(port=8080, targetPort=this._config.httpPort)
                 + k.core.v1.servicePort.withName('http'),
                 k.core.v1.servicePort.new(port=8443, targetPort=this._config.httpsPort)
                 + k.core.v1.servicePort.withName('https'),
               ],
             )
             + k.core.v1.service.metadata.withNamespace(this._config.namespace)
             + k.core.v1.service.metadata.withLabels(this._config.labels)
             + k.core.v1.service.spec.withType('LoadBalancer'),

    // Deployment
    deployment: k.apps.v1.deployment.new(
                  name=this._config.name,
                  replicas=1,
                  containers=[
                    k.core.v1.container.new('keycloak', this._config.image)
                    + k.core.v1.container.withPorts([
                      k.core.v1.containerPort.new(this._config.httpPort)
                      + k.core.v1.containerPort.withName('http'),
                      k.core.v1.containerPort.new(this._config.httpsPort)
                      + k.core.v1.containerPort.withName('https'),
                      k.core.v1.containerPort.new(9000)
                      + k.core.v1.containerPort.withName('management'),
                    ])
                    + k.core.v1.container.withEnv([
                      k.core.v1.envVar.new('KEYCLOAK_ADMIN', this._config.adminUser),
                      k.core.v1.envVar.new('KEYCLOAK_ADMIN_PASSWORD', this._config.adminPassword),
                      k.core.v1.envVar.new('KC_PROXY', 'edge'),
                      k.core.v1.envVar.new('KC_HEALTH_ENABLED', 'true'),
                      k.core.v1.envVar.new('KC_METRICS_ENABLED', 'true'),
                      k.core.v1.envVar.new('KC_HTTP_ENABLED', 'true'),
                    ])
                    + k.core.v1.container.withArgs([
                      'start-dev',
                    ])
                    + k.core.v1.container.withVolumeMounts([
                      k.core.v1.volumeMount.new('data', '/opt/keycloak/data'),
                    ])
                    + k.core.v1.container.resources.withRequests({
                      cpu: '500m',
                      memory: '512Mi',
                    })
                    + k.core.v1.container.resources.withLimits({
                      cpu: '2',
                      memory: '2Gi',
                    })
                    + k.core.v1.container.livenessProbe.httpGet.withPath('/health/live')
                    + k.core.v1.container.livenessProbe.httpGet.withPort('management')
                    + k.core.v1.container.livenessProbe.withInitialDelaySeconds(120)
                    + k.core.v1.container.livenessProbe.withPeriodSeconds(10)
                    + k.core.v1.container.livenessProbe.withFailureThreshold(5)
                    + k.core.v1.container.readinessProbe.httpGet.withPath('/health/ready')
                    + k.core.v1.container.readinessProbe.httpGet.withPort('management')
                    + k.core.v1.container.readinessProbe.withInitialDelaySeconds(60)
                    + k.core.v1.container.readinessProbe.withPeriodSeconds(10)
                    + k.core.v1.container.readinessProbe.withFailureThreshold(5),
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
