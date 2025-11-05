local k = import 'k.libsonnet';

{
  new(namespace='traefik'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      version: 'v2.11',
      replicas: 1,
      labels: {
        app: 'traefik',
      },
      serviceType: 'LoadBalancer',
    },

    namespace: k.core.v1.namespace.new(this._config.namespace)
      + k.core.v1.namespace.metadata.withLabels(this._config.labels),

    // ServiceAccount
    serviceAccount: k.core.v1.serviceAccount.new('traefik')
      + k.core.v1.serviceAccount.metadata.withNamespace(this._config.namespace)
      + k.core.v1.serviceAccount.metadata.withLabels(this._config.labels),

    // ClusterRole
    clusterRole: k.rbac.v1.clusterRole.new('traefik')
      + k.rbac.v1.clusterRole.withRules([
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['services', 'endpoints', 'secrets'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
        k.rbac.v1.policyRule.withApiGroups(['extensions', 'networking.k8s.io'])
        + k.rbac.v1.policyRule.withResources(['ingresses', 'ingressclasses'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
        k.rbac.v1.policyRule.withApiGroups(['extensions', 'networking.k8s.io'])
        + k.rbac.v1.policyRule.withResources(['ingresses/status'])
        + k.rbac.v1.policyRule.withVerbs(['update']),
        k.rbac.v1.policyRule.withApiGroups(['traefik.io', 'traefik.containo.us'])
        + k.rbac.v1.policyRule.withResources([
          'middlewares',
          'middlewaretcps',
          'ingressroutes',
          'traefikservices',
          'ingressroutetcps',
          'ingressrouteudps',
          'tlsoptions',
          'tlsstores',
          'serverstransports'
        ])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
      ])
      + k.rbac.v1.clusterRole.metadata.withLabels(this._config.labels),

    // ClusterRoleBinding
    clusterRoleBinding: k.rbac.v1.clusterRoleBinding.new('traefik')
      + k.rbac.v1.clusterRoleBinding.bindRole(this.clusterRole)
      + k.rbac.v1.clusterRoleBinding.withSubjects([
        k.rbac.v1.subject.fromServiceAccount(this.serviceAccount),
      ])
      + k.rbac.v1.clusterRoleBinding.metadata.withLabels(this._config.labels),

    // Deployment
    deployment: k.apps.v1.deployment.new(
      name='traefik',
      replicas=this._config.replicas,
      containers=[
        k.core.v1.container.new(
          name='traefik',
          image='traefik:%s' % this._config.version,
        )
        + k.core.v1.container.withPorts([
          k.core.v1.containerPort.new(8000)
            + k.core.v1.containerPort.withName('web')
            + k.core.v1.containerPort.withProtocol('TCP'),
          k.core.v1.containerPort.new(8443)
            + k.core.v1.containerPort.withName('websecure')
            + k.core.v1.containerPort.withProtocol('TCP'),
          k.core.v1.containerPort.new(9000)
            + k.core.v1.containerPort.withName('admin')
            + k.core.v1.containerPort.withProtocol('TCP'),
        ])
        + k.core.v1.container.withArgs([
          '--api.insecure=true',
          '--api.dashboard=true',
          '--ping=true',
          '--accesslog=true',
          '--entrypoints.web.address=:8000',
          '--entrypoints.websecure.address=:8443',
          '--entrypoints.traefik.address=:9000',
          '--providers.kubernetescrd=true',
          '--providers.kubernetesingress=true',
          '--log.level=INFO',
          '--metrics.prometheus=true',
          '--metrics.prometheus.entrypoint=traefik',

        ])
        + k.core.v1.container.securityContext.withAllowPrivilegeEscalation(false)
        + k.core.v1.container.securityContext.withRunAsNonRoot(true)
        + k.core.v1.container.securityContext.withRunAsUser(65532)
        + k.core.v1.container.securityContext.withRunAsGroup(65532)
        + k.core.v1.container.securityContext.capabilities.withDrop(['ALL'])
        + k.core.v1.container.securityContext.withReadOnlyRootFilesystem(true)
        + k.core.v1.container.resources.withRequests({
          cpu: '100m',
          memory: '128Mi',
        })
        + k.core.v1.container.resources.withLimits({
          cpu: '1000m',
          memory: '512Mi',
        })
        + k.core.v1.container.livenessProbe.httpGet.withPath('/ping')
        + k.core.v1.container.livenessProbe.httpGet.withPort(9000)
        + k.core.v1.container.livenessProbe.withInitialDelaySeconds(10)
        + k.core.v1.container.livenessProbe.withPeriodSeconds(10)
        + k.core.v1.container.readinessProbe.httpGet.withPath('/ping')
        + k.core.v1.container.readinessProbe.httpGet.withPort(9000)
        + k.core.v1.container.readinessProbe.withInitialDelaySeconds(5)
        + k.core.v1.container.readinessProbe.withPeriodSeconds(5),
      ],
    )
    + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
    + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
    + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
    + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
    + k.apps.v1.deployment.spec.template.spec.withServiceAccountName('traefik')
    + k.apps.v1.deployment.spec.template.spec.securityContext.withFsGroup(65532)
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

    // Service for HTTP/HTTPS traffic
    service: k.core.v1.service.new(
      name='traefik',
      selector=this._config.labels,
      ports=[
        k.core.v1.servicePort.new(port=80, targetPort=8000)
          + k.core.v1.servicePort.withName('web')
          + k.core.v1.servicePort.withProtocol('TCP'),
        k.core.v1.servicePort.new(port=443, targetPort=8443)
          + k.core.v1.servicePort.withName('websecure')
          + k.core.v1.servicePort.withProtocol('TCP'),
      ],
    )
    + k.core.v1.service.metadata.withNamespace(this._config.namespace)
    + k.core.v1.service.metadata.withLabels(this._config.labels)
    + k.core.v1.service.spec.withType(this._config.serviceType),

    // Dashboard Service (internal only)
    dashboardService: k.core.v1.service.new(
      name='traefik-dashboard',
      selector=this._config.labels,
      ports=[
        k.core.v1.servicePort.new(port=9000, targetPort=9000)
          + k.core.v1.servicePort.withName('dashboard')
          + k.core.v1.servicePort.withProtocol('TCP'),
      ],
    )
    + k.core.v1.service.metadata.withNamespace(this._config.namespace)
    + k.core.v1.service.metadata.withLabels(this._config.labels)
    + k.core.v1.service.spec.withType('ClusterIP'),

    // IngressClass
    ingressClass: {
      apiVersion: 'networking.k8s.io/v1',
      kind: 'IngressClass',
      metadata: {
        name: 'traefik',
        labels: this._config.labels,
        annotations: {
          'ingressclass.kubernetes.io/is-default-class': 'true',
        },
      },
      spec: {
        controller: 'traefik.io/ingress-controller',
      },
    },
  },

  withReplicas(replicas):: {
    _config+:: { replicas: replicas },
    deployment+: k.apps.v1.deployment.spec.withReplicas(replicas),
  },

  withServiceType(serviceType):: {
    _config+:: { serviceType: serviceType },
    service+: k.core.v1.service.spec.withType(serviceType),
  },

  withVersion(version):: {
    _config+:: { version: version },
    deployment+: k.apps.v1.deployment.spec.template.spec.withContainers([
      super.deployment.spec.template.spec.containers[0] +
      k.core.v1.container.withImage('traefik:%s' % version),
    ]),
  },

  // Add dashboard ingress route using Traefik CRD
  withDashboardIngress(host):: {
    dashboardIngressRoute: {
      apiVersion: 'traefik.io/v1alpha1',
      kind: 'IngressRoute',
      metadata: {
        name: 'traefik-dashboard',
        namespace: self._config.namespace,
        labels: self._config.labels,
      },
      spec: {
        entryPoints: ['web'],
        routes: [
          {
            match: 'Host(`%s`)' % host,
            kind: 'Rule',
            services: [
              {
                name: 'api@internal',
                kind: 'TraefikService',
              },
            ],
          },
        ],
      },
    },
  },

  // Add Let's Encrypt configuration
  withLetsEncrypt(email, staging=false):: {
    local letsEncryptArgs = [
      '--certificatesresolvers.letsencrypt.acme.email=%s' % email,
      '--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json',
      '--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web',
    ] + (if staging then ['--certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory'] else []),

    deployment+: k.apps.v1.deployment.spec.template.spec.withContainers([
      super.deployment.spec.template.spec.containers[0] +
      k.core.v1.container.withArgs(
        super.deployment.spec.template.spec.containers[0].args + letsEncryptArgs
      ) +
      k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('data', '/data'),
      ]),
    ]) +
    k.apps.v1.deployment.spec.template.spec.withVolumes([
      k.core.v1.volume.fromEmptyDir('data'),
    ]),
  },

  // Add middleware for HTTPS redirect
  withHTTPSRedirect():: {
    httpsRedirectMiddleware: {
      apiVersion: 'traefik.io/v1alpha1',
      kind: 'Middleware',
      metadata: {
        name: 'https-redirect',
        namespace: self._config.namespace,
        labels: self._config.labels,
      },
      spec: {
        redirectScheme: {
          scheme: 'https',
          permanent: true,
        },
      },
    },
  },

  // Add IP whitelist middleware
  withIPWhitelist(name, sourceRange):: {
    ['ipWhitelistMiddleware_%s' % name]: {
      apiVersion: 'traefik.io/v1alpha1',
      kind: 'Middleware',
      metadata: {
        name: name,
        namespace: self._config.namespace,
        labels: self._config.labels,
      },
      spec: {
        ipWhiteList: {
          sourceRange: if std.isArray(sourceRange) then sourceRange else [sourceRange],
        },
      },
    },
  },
}
