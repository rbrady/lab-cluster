local k = import 'k.libsonnet';

{
  new(name, image, replicas=1, port=80):: {
    local this = self,

    _config:: {
      name: name,
      image: image,
      replicas: replicas,
      port: port,
      labels: {
        app: name,
      },
    },

    deployment: k.apps.v1.deployment.new(
      name=this._config.name,
      replicas=this._config.replicas,
      containers=[
        k.core.v1.container.new(
          name=this._config.name,
          image=this._config.image,
        )
        + k.core.v1.container.withPorts([
          k.core.v1.containerPort.new(this._config.port),
        ]),
      ],
    )
    + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
    + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
    + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
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

    service: k.core.v1.service.new(
      name=this._config.name,
      selector=this._config.labels,
      ports=[
        k.core.v1.servicePort.new(
          port=this._config.port,
          targetPort=this._config.port,
        ),
      ],
    )
    + k.core.v1.service.metadata.withLabels(this._config.labels),
  },

  withReplicas(replicas):: {
    deployment+: k.apps.v1.deployment.spec.withReplicas(replicas),
  },

  withEnv(env):: {
    deployment+: k.apps.v1.deployment.spec.template.spec.containers[0]+
      k.core.v1.container.withEnv(env),
  },

  withServiceType(type):: {
    service+: k.core.v1.service.spec.withType(type),
  },
}
