local k = import 'k.libsonnet';

{
  new(namespace='kube-system'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      name: 'kube-state-metrics',
      image: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.1',
      port: 8080,
      telemetryPort: 8081,
      labels: {
        app: 'kube-state-metrics',
        'app.kubernetes.io/name': 'kube-state-metrics',
      },
    },

    // Namespace
    namespace: k.core.v1.namespace.new(this._config.namespace)
               + k.core.v1.namespace.metadata.withLabels(this._config.labels),

    // ServiceAccount
    serviceAccount: k.core.v1.serviceAccount.new(this._config.name)
                    + k.core.v1.serviceAccount.metadata.withNamespace(this._config.namespace)
                    + k.core.v1.serviceAccount.metadata.withLabels(this._config.labels),

    // ClusterRole - needs cluster-wide read access
    clusterRole: k.rbac.v1.clusterRole.new(this._config.name)
                 + k.rbac.v1.clusterRole.metadata.withLabels(this._config.labels)
                 + k.rbac.v1.clusterRole.withRules([
                   {
                     apiGroups: [''],
                     resources: [
                       'configmaps',
                       'secrets',
                       'nodes',
                       'pods',
                       'services',
                       'serviceaccounts',
                       'resourcequotas',
                       'replicationcontrollers',
                       'limitranges',
                       'persistentvolumeclaims',
                       'persistentvolumes',
                       'namespaces',
                       'endpoints',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['apps'],
                     resources: [
                       'statefulsets',
                       'daemonsets',
                       'deployments',
                       'replicasets',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['batch'],
                     resources: [
                       'cronjobs',
                       'jobs',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['autoscaling'],
                     resources: [
                       'horizontalpodautoscalers',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['authentication.k8s.io'],
                     resources: [
                       'tokenreviews',
                     ],
                     verbs: ['create'],
                   },
                   {
                     apiGroups: ['authorization.k8s.io'],
                     resources: [
                       'subjectaccessreviews',
                     ],
                     verbs: ['create'],
                   },
                   {
                     apiGroups: ['policy'],
                     resources: [
                       'poddisruptionbudgets',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['certificates.k8s.io'],
                     resources: [
                       'certificatesigningrequests',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['storage.k8s.io'],
                     resources: [
                       'storageclasses',
                       'volumeattachments',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['admissionregistration.k8s.io'],
                     resources: [
                       'mutatingwebhookconfigurations',
                       'validatingwebhookconfigurations',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['networking.k8s.io'],
                     resources: [
                       'networkpolicies',
                       'ingresses',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['coordination.k8s.io'],
                     resources: [
                       'leases',
                     ],
                     verbs: ['list', 'watch'],
                   },
                   {
                     apiGroups: ['rbac.authorization.k8s.io'],
                     resources: [
                       'clusterrolebindings',
                       'clusterroles',
                       'rolebindings',
                       'roles',
                     ],
                     verbs: ['list', 'watch'],
                   },
                 ]),

    // ClusterRoleBinding
    clusterRoleBinding: k.rbac.v1.clusterRoleBinding.new(this._config.name)
                        + k.rbac.v1.clusterRoleBinding.metadata.withLabels(this._config.labels)
                        + k.rbac.v1.clusterRoleBinding.bindRole(this.clusterRole)
                        + k.rbac.v1.clusterRoleBinding.withSubjects([
                          {
                            kind: 'ServiceAccount',
                            name: this._config.name,
                            namespace: this._config.namespace,
                          },
                        ]),

    // Deployment
    deployment: k.apps.v1.deployment.new(
                  name=this._config.name,
                  replicas=1,
                  containers=[
                    k.core.v1.container.new('kube-state-metrics', this._config.image)
                    + k.core.v1.container.withPorts([
                      k.core.v1.containerPort.new(this._config.port)
                      + k.core.v1.containerPort.withName('http-metrics'),
                      k.core.v1.containerPort.new(this._config.telemetryPort)
                      + k.core.v1.containerPort.withName('telemetry'),
                    ])
                    + k.core.v1.container.withArgs([
                      '--port=' + this._config.port,
                      '--telemetry-port=' + this._config.telemetryPort,
                    ])
                    + k.core.v1.container.resources.withRequests({
                      cpu: '10m',
                      memory: '32Mi',
                    })
                    + k.core.v1.container.resources.withLimits({
                      cpu: '200m',
                      memory: '256Mi',
                    })
                    + k.core.v1.container.livenessProbe.httpGet.withPath('/healthz')
                    + k.core.v1.container.livenessProbe.httpGet.withPort(this._config.port)
                    + k.core.v1.container.livenessProbe.withInitialDelaySeconds(5)
                    + k.core.v1.container.livenessProbe.withTimeoutSeconds(5)
                    + k.core.v1.container.readinessProbe.httpGet.withPath('/')
                    + k.core.v1.container.readinessProbe.httpGet.withPort(this._config.telemetryPort)
                    + k.core.v1.container.readinessProbe.withInitialDelaySeconds(5)
                    + k.core.v1.container.readinessProbe.withTimeoutSeconds(5),
                  ],
                )
                + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
                + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.spec.withServiceAccountName(this._config.name)
                + k.apps.v1.deployment.spec.template.spec.securityContext.withRunAsUser(65534)
                + k.apps.v1.deployment.spec.template.spec.securityContext.withRunAsGroup(65534)
                + k.apps.v1.deployment.spec.template.spec.securityContext.withFsGroup(65534)
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
                 + k.core.v1.servicePort.withName('http-metrics'),
                 k.core.v1.servicePort.new(port=this._config.telemetryPort, targetPort=this._config.telemetryPort)
                 + k.core.v1.servicePort.withName('telemetry'),
               ],
             )
             + k.core.v1.service.metadata.withNamespace(this._config.namespace)
             + k.core.v1.service.metadata.withLabels(this._config.labels)
             + k.core.v1.service.metadata.withAnnotations({
               'prometheus.io/scrape': 'true',
               'prometheus.io/port': std.toString(this._config.port),
             })
             + k.core.v1.service.spec.withType('ClusterIP'),
  },
}
