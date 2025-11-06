local k = import 'k.libsonnet';

{
  new(namespace='kube-system'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      name: 'node-exporter',
      image: 'prom/node-exporter:v1.7.0',
      port: 9100,
      labels: {
        app: 'node-exporter',
        'app.kubernetes.io/name': 'node-exporter',
      },
    },

    // ServiceAccount
    serviceAccount: k.core.v1.serviceAccount.new(this._config.name)
                    + k.core.v1.serviceAccount.metadata.withNamespace(this._config.namespace)
                    + k.core.v1.serviceAccount.metadata.withLabels(this._config.labels),

    // DaemonSet - runs on every node
    daemonSet: k.apps.v1.daemonSet.new(
                 name=this._config.name,
                 containers=[
                   k.core.v1.container.new('node-exporter', this._config.image)
                   + k.core.v1.container.withArgs([
                     '--path.sysfs=/host/sys',
                     '--path.rootfs=/host/root',
                     '--path.procfs=/host/proc',
                     '--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)',
                     '--collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$',
                   ])
                   + k.core.v1.container.withPorts([
                     k.core.v1.containerPort.new(this._config.port)
                     + k.core.v1.containerPort.withName('metrics')
                     + k.core.v1.containerPort.withProtocol('TCP'),
                   ])
                   + k.core.v1.container.withVolumeMounts([
                     k.core.v1.volumeMount.new('proc', '/host/proc')
                     + k.core.v1.volumeMount.withMountPropagation('HostToContainer')
                     + k.core.v1.volumeMount.withReadOnly(true),
                     k.core.v1.volumeMount.new('sys', '/host/sys')
                     + k.core.v1.volumeMount.withMountPropagation('HostToContainer')
                     + k.core.v1.volumeMount.withReadOnly(true),
                     k.core.v1.volumeMount.new('root', '/host/root')
                     + k.core.v1.volumeMount.withMountPropagation('HostToContainer')
                     + k.core.v1.volumeMount.withReadOnly(true),
                   ])
                   + k.core.v1.container.resources.withRequests({
                     cpu: '10m',
                     memory: '24Mi',
                   })
                   + k.core.v1.container.resources.withLimits({
                     cpu: '200m',
                     memory: '128Mi',
                   }),
                 ],
               )
               + k.apps.v1.daemonSet.metadata.withNamespace(this._config.namespace)
               + k.apps.v1.daemonSet.metadata.withLabels(this._config.labels)
               + k.apps.v1.daemonSet.spec.selector.withMatchLabels(this._config.labels)
               + k.apps.v1.daemonSet.spec.template.metadata.withLabels(this._config.labels)
               + k.apps.v1.daemonSet.spec.template.spec.withServiceAccountName(this._config.name)
               + k.apps.v1.daemonSet.spec.template.spec.withHostNetwork(true)
               + k.apps.v1.daemonSet.spec.template.spec.withHostPID(true)
               + k.apps.v1.daemonSet.spec.template.spec.withVolumes([
                 k.core.v1.volume.fromHostPath('proc', '/proc'),
                 k.core.v1.volume.fromHostPath('sys', '/sys'),
                 k.core.v1.volume.fromHostPath('root', '/'),
               ])
               + k.apps.v1.daemonSet.spec.template.spec.withTolerations([
                 {
                   effect: 'NoSchedule',
                   operator: 'Exists',
                 },
               ])
               + k.apps.v1.daemonSet.spec.template.spec.securityContext.withRunAsNonRoot(true)
               + k.apps.v1.daemonSet.spec.template.spec.securityContext.withRunAsUser(65534),

    // Service
    service: k.core.v1.service.new(
               name=this._config.name,
               selector=this._config.labels,
               ports=[
                 k.core.v1.servicePort.new(port=this._config.port, targetPort=this._config.port)
                 + k.core.v1.servicePort.withName('metrics'),
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
