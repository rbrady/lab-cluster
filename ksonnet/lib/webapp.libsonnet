local k = import 'k.libsonnet';

{
  new(name, image, namespace='default'):: {
    local this = self,

    _config:: {
      name: name,
      image: image,
      namespace: namespace,
      replicas: 1,
      port: 8080,
      resources: {
        requests: {
          cpu: '100m',
          memory: '128Mi',
        },
        limits: {
          cpu: '500m',
          memory: '512Mi',
        },
      },
      labels: {
        app: name,
        component: 'webapp',
      },
      env: {},
    },

    configMap: k.core.v1.configMap.new(
      name='%s-config' % this._config.name,
      data={
        'app.conf': |||
          # Application configuration
          port: %d
          environment: production
        ||| % this._config.port,
      },
    )
    + k.core.v1.configMap.metadata.withNamespace(this._config.namespace)
    + k.core.v1.configMap.metadata.withLabels(this._config.labels),

    deployment: k.apps.v1.deployment.new(
      name=this._config.name,
      replicas=this._config.replicas,
      containers=[
        k.core.v1.container.new(
          name=this._config.name,
          image=this._config.image,
        )
        + k.core.v1.container.withPorts([
          k.core.v1.containerPort.new('http', this._config.port),
        ])
        + k.core.v1.container.resources.withRequests(this._config.resources.requests)
        + k.core.v1.container.resources.withLimits(this._config.resources.limits)
        + k.core.v1.container.withEnvFrom([
          k.core.v1.envFromSource.configMapRef.withName('%s-config' % this._config.name),
        ])
        + k.core.v1.container.withVolumeMounts([
          k.core.v1.volumeMount.new(
            name='config',
            mountPath='/etc/config',
          ),
        ]),
      ],
    )
    + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
    + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
    + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
    + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
    + k.apps.v1.deployment.spec.template.spec.withVolumes([
      k.core.v1.volume.fromConfigMap(
        name='config',
        configMapName='%s-config' % this._config.name,
      ),
    ]),

    service: k.core.v1.service.new(
      name=this._config.name,
      selector=this._config.labels,
      ports=[
        k.core.v1.servicePort.new(
          name='http',
          port=80,
          targetPort='http',
        ),
      ],
    )
    + k.core.v1.service.metadata.withNamespace(this._config.namespace)
    + k.core.v1.service.metadata.withLabels(this._config.labels),
  },

  // Modifiers
  withReplicas(replicas):: {
    _config+:: { replicas: replicas },
    deployment+: k.apps.v1.deployment.spec.withReplicas(replicas),
  },

  withPort(port):: {
    _config+:: { port: port },
    deployment+: k.apps.v1.deployment.spec.template.spec.containers[0]+:
      k.core.v1.container.withPorts([
        k.core.v1.containerPort.new('http', port),
      ]),
  },

  withServiceType(type):: {
    service+: k.core.v1.service.spec.withType(type),
  },

  withEnv(env):: {
    _config+:: { env: env },
    deployment+: k.apps.v1.deployment.spec.template.spec.containers[0]+:
      k.core.v1.container.withEnv([
        k.core.v1.envVar.new(key, env[key])
        for key in std.objectFields(env)
      ]),
  },

  withResources(requests, limits):: {
    _config+:: {
      resources: {
        requests: requests,
        limits: limits,
      },
    },
    deployment+: k.apps.v1.deployment.spec.template.spec.containers[0]+:
      k.core.v1.container.resources.withRequests(requests)
      + k.core.v1.container.resources.withLimits(limits),
  },

  withIngress(host, path='/', ingressClass='nginx'):: {
    ingress: k.networking.v1.ingress.new(self._config.name)
      + k.networking.v1.ingress.metadata.withNamespace(self._config.namespace)
      + k.networking.v1.ingress.metadata.withLabels(self._config.labels)
      + k.networking.v1.ingress.metadata.withAnnotations({
        'kubernetes.io/ingress.class': ingressClass,
      })
      + k.networking.v1.ingress.spec.withRules([
        k.networking.v1.ingressRule.withHost(host)
        + k.networking.v1.ingressRule.http.withPaths([
          k.networking.v1.httpIngressPath.withPath(path)
          + k.networking.v1.httpIngressPath.withPathType('Prefix')
          + k.networking.v1.httpIngressPath.backend.service.withName(self._config.name)
          + k.networking.v1.httpIngressPath.backend.service.port.withNumber(80),
        ]),
      ]),
  },

  withReadinessProbe(path='/health', port='http'):: {
    deployment+: k.apps.v1.deployment.spec.template.spec.containers[0]+:
      k.core.v1.container.withReadinessProbe(
        k.core.v1.probe.httpGet.withPath(path)
        + k.core.v1.probe.httpGet.withPort(port)
        + k.core.v1.probe.withInitialDelaySeconds(10)
        + k.core.v1.probe.withPeriodSeconds(5)
      ),
  },

  withLivenessProbe(path='/health', port='http'):: {
    deployment+: k.apps.v1.deployment.spec.template.spec.containers[0]+:
      k.core.v1.container.withLivenessProbe(
        k.core.v1.probe.httpGet.withPath(path)
        + k.core.v1.probe.httpGet.withPort(port)
        + k.core.v1.probe.withInitialDelaySeconds(30)
        + k.core.v1.probe.withPeriodSeconds(10)
      ),
  },
}
