local k = import 'k.libsonnet';

{
  new(namespace='local-path-storage'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      name: 'local-path-provisioner',
      labels: {
        app: 'local-path-provisioner',
      },
      // add more config here

    },

    // start adding resources here
    namespace: k.core.v1.namespace.new(this._config.namespace)
               + k.core.v1.namespace.metadata.withLabels(this._config.labels),

    serviceAccount: k.core.v1.serviceAccount.new('local-path-provisioner-service-account')
                    + k.core.v1.serviceAccount.metadata.withNamespace(this._config.namespace)
                    + k.core.v1.serviceAccount.metadata.withLabels(this._config.labels),

    role: k.rbac.v1.role.new('local-path-provisioner-role')
          + k.rbac.v1.role.metadata.withNamespace(this._config.namespace)
          + k.rbac.v1.role.metadata.withLabels(this._config.labels)
          + k.rbac.v1.role.withRules([
            k.rbac.v1.policyRule.withApiGroups([''])
            + k.rbac.v1.policyRule.withResources(['pods'])
            + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch', 'create', 'patch', 'delete', 'update']),
          ]),

    clusterRole: k.rbac.v1.clusterRole.new('local-path-provisioner-cluster-role')
                 + k.rbac.v1.clusterRole.metadata.withLabels(this._config.labels)
                 + k.rbac.v1.clusterRole.withRules([
                   k.rbac.v1.policyRule.withApiGroups([''])
                   + k.rbac.v1.policyRule.withResources(['nodes', 'persistentvolumeclaims', 'configmaps', 'pods', 'pods/log'])
                   + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
                   k.rbac.v1.policyRule.withApiGroups([''])
                   + k.rbac.v1.policyRule.withResources(['persistentvolumes'])
                   + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch', 'create', 'patch', 'delete', 'update']),
                   k.rbac.v1.policyRule.withApiGroups([''])
                   + k.rbac.v1.policyRule.withResources(['events'])
                   + k.rbac.v1.policyRule.withVerbs(['create', 'patch']),
                   k.rbac.v1.policyRule.withApiGroups(['storage.k8s.io'])
                   + k.rbac.v1.policyRule.withResources(['storageclasses'])
                   + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
                 ]),

    roleBinding: k.rbac.v1.roleBinding.new('local-path-provisioner-bind')
                 + k.rbac.v1.roleBinding.metadata.withNamespace(this._config.namespace)
                 + k.rbac.v1.roleBinding.metadata.withLabels(this._config.labels)
                 + k.rbac.v1.roleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io')
                 + k.rbac.v1.roleBinding.roleRef.withKind('Role')
                 + k.rbac.v1.roleBinding.roleRef.withName('local-path-provisioner-role')
                 + k.rbac.v1.roleBinding.withSubjects([
                   k.rbac.v1.subject.withKind('ServiceAccount')
                   + k.rbac.v1.subject.withName('local-path-provisioner-service-account')
                   + k.rbac.v1.subject.withNamespace(this._config.namespace),
                 ]),

    clusterRoleBinding: k.rbac.v1.clusterRoleBinding.new('local-path-provisioner-bind')
                        + k.rbac.v1.clusterRoleBinding.metadata.withLabels(this._config.labels)
                        + k.rbac.v1.clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io')
                        + k.rbac.v1.clusterRoleBinding.roleRef.withKind('ClusterRole')
                        + k.rbac.v1.clusterRoleBinding.roleRef.withName('local-path-provisioner-cluster-role')
                        + k.rbac.v1.clusterRoleBinding.withSubjects([
                          k.rbac.v1.subject.withKind('ServiceAccount')
                          + k.rbac.v1.subject.withName('local-path-provisioner-service-account')
                          + k.rbac.v1.subject.withNamespace(this._config.namespace),
                        ]),

    configMap: k.core.v1.configMap.new('local-path-config')
               + k.core.v1.configMap.metadata.withNamespace(this._config.namespace)
               + k.core.v1.configMap.metadata.withLabels(this._config.labels)
               + k.core.v1.configMap.withData({
                 'config.json': std.manifestJsonEx({
                   nodePathMap: [
                     {
                       node: 'DEFAULT_PATH_FOR_NON_LISTED_NODES',
                       paths: ['/opt/local-path-provisioner'],
                     },
                   ],
                 }, '  '),
                 setup: |||
                   #!/bin/sh
                   set -eu
                   mkdir -m 0777 -p "$VOL_DIR"
                 |||,
                 teardown: |||
                   #!/bin/sh
                   set -eu
                   rm -rf "$VOL_DIR"
                 |||,
                 'helperPod.yaml': |||
                   apiVersion: v1
                   kind: Pod
                   metadata:
                     name: helper-pod
                   spec:
                     priorityClassName: system-node-critical
                     tolerations:
                       - key: node.kubernetes.io/disk-pressure
                         operator: Exists
                         effect: NoSchedule
                     containers:
                     - name: helper-pod
                       image: busybox
                       imagePullPolicy: IfNotPresent
                 |||,
               }),
    deployment: k.apps.v1.deployment.new(
                  name='local-path-provisioner',
                  replicas=1,
                  containers=[
                    k.core.v1.container.new('local-path-provisioner', 'rancher/local-path-provisioner:v0.0.28')
                    + k.core.v1.container.withImagePullPolicy('IfNotPresent')
                    + k.core.v1.container.withCommand([
                      'local-path-provisioner',
                      '--debug',
                      'start',
                      '--config',
                      '/etc/config/config.json',
                    ])
                    + k.core.v1.container.withVolumeMounts([
                      k.core.v1.volumeMount.new('config-volume', '/etc/config/'),
                    ])
                    + k.core.v1.container.withEnv([
                      k.core.v1.envVar.new('POD_NAMESPACE', '')
                      + k.core.v1.envVar.valueFrom.fieldRef.withFieldPath('metadata.namespace'),
                      k.core.v1.envVar.new('CONFIG_MOUNT_PATH', '/etc/config/'),
                    ]),
                  ],
                )
                + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
                + k.apps.v1.deployment.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels)
                + k.apps.v1.deployment.spec.template.spec.withServiceAccountName('local-path-provisioner-service-account')
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
                ])

                + k.apps.v1.deployment.spec.template.spec.withVolumes([
                  k.core.v1.volume.fromConfigMap('config-volume', 'local-path-config'),
                ]),
    storageClass: k.storage.v1.storageClass.new('local-path')
                  + k.storage.v1.storageClass.metadata.withLabels(this._config.labels)
                  + k.storage.v1.storageClass.withProvisioner('rancher.io/local-path')
                  + k.storage.v1.storageClass.withVolumeBindingMode('WaitForFirstConsumer')
                  + k.storage.v1.storageClass.withReclaimPolicy('Delete'),

  },
}
