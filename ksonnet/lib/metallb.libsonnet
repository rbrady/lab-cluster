local k = import 'k.libsonnet';

{
  new(namespace='metallb-system'):: {
    local this = self,

    _config:: {
      namespace: namespace,
      version: 'v0.14.3',
      labels: {
        app: 'metallb',
      },
    },

    namespace: k.core.v1.namespace.new(this._config.namespace)
      + k.core.v1.namespace.metadata.withLabels(this._config.labels),

    // CRDs - Custom Resource Definitions
    ipAddressPoolCRD: {
      apiVersion: 'apiextensions.k8s.io/v1',
      kind: 'CustomResourceDefinition',
      metadata: {
        name: 'ipaddresspools.metallb.io',
      },
      spec: {
        group: 'metallb.io',
        names: {
          kind: 'IPAddressPool',
          listKind: 'IPAddressPoolList',
          plural: 'ipaddresspools',
          singular: 'ipaddresspool',
        },
        scope: 'Namespaced',
        versions: [
          {
            name: 'v1beta1',
            served: true,
            storage: true,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      addresses: {
                        type: 'array',
                        items: {
                          type: 'string',
                        },
                      },
                      autoAssign: {
                        type: 'boolean',
                      },
                      avoidBuggyIPs: {
                        type: 'boolean',
                      },
                    },
                    required: ['addresses'],
                  },
                },
              },
            },
          },
        ],
      },
    },

    l2AdvertisementCRD: {
      apiVersion: 'apiextensions.k8s.io/v1',
      kind: 'CustomResourceDefinition',
      metadata: {
        name: 'l2advertisements.metallb.io',
      },
      spec: {
        group: 'metallb.io',
        names: {
          kind: 'L2Advertisement',
          listKind: 'L2AdvertisementList',
          plural: 'l2advertisements',
          singular: 'l2advertisement',
        },
        scope: 'Namespaced',
        versions: [
          {
            name: 'v1beta1',
            served: true,
            storage: true,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      ipAddressPools: {
                        type: 'array',
                        items: {
                          type: 'string',
                        },
                      },
                      ipAddressPoolSelectors: {
                        type: 'array',
                        items: {
                          type: 'object',
                        },
                      },
                      nodeSelectors: {
                        type: 'array',
                        items: {
                          type: 'object',
                        },
                      },
                      interfaces: {
                        type: 'array',
                        items: {
                          type: 'string',
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        ],
      },
    },

    // BGPPeer CRD
    bgpPeerCRD: {
      apiVersion: 'apiextensions.k8s.io/v1',
      kind: 'CustomResourceDefinition',
      metadata: {
        name: 'bgppeers.metallb.io',
      },
      spec: {
        group: 'metallb.io',
        names: {
          kind: 'BGPPeer',
          listKind: 'BGPPeerList',
          plural: 'bgppeers',
          singular: 'bgppeer',
        },
        scope: 'Namespaced',
        versions: [
          {
            name: 'v1beta2',
            served: true,
            storage: false,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      myASN: { type: 'integer' },
                      peerASN: { type: 'integer' },
                      peerAddress: { type: 'string' },
                      peerPort: { type: 'integer' },
                      routerID: { type: 'string' },
                    },
                  },
                },
              },
            },
          },
          {
            name: 'v1beta1',
            served: true,
            storage: true,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      myASN: { type: 'integer' },
                      peerASN: { type: 'integer' },
                      peerAddress: { type: 'string' },
                      peerPort: { type: 'integer' },
                      routerID: { type: 'string' },
                    },
                  },
                },
              },
            },
          },
        ],
      },
    },

    // BGPAdvertisement CRD
    bgpAdvertisementCRD: {
      apiVersion: 'apiextensions.k8s.io/v1',
      kind: 'CustomResourceDefinition',
      metadata: {
        name: 'bgpadvertisements.metallb.io',
      },
      spec: {
        group: 'metallb.io',
        names: {
          kind: 'BGPAdvertisement',
          listKind: 'BGPAdvertisementList',
          plural: 'bgpadvertisements',
          singular: 'bgpadvertisement',
        },
        scope: 'Namespaced',
        versions: [
          {
            name: 'v1beta1',
            served: true,
            storage: true,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      ipAddressPools: {
                        type: 'array',
                        items: { type: 'string' },
                      },
                      aggregationLength: { type: 'integer' },
                      localPref: { type: 'integer' },
                      communities: {
                        type: 'array',
                        items: { type: 'string' },
                      },
                    },
                  },
                },
              },
            },
          },
        ],
      },
    },

    // BFDProfile CRD
    bfdProfileCRD: {
      apiVersion: 'apiextensions.k8s.io/v1',
      kind: 'CustomResourceDefinition',
      metadata: {
        name: 'bfdprofiles.metallb.io',
      },
      spec: {
        group: 'metallb.io',
        names: {
          kind: 'BFDProfile',
          listKind: 'BFDProfileList',
          plural: 'bfdprofiles',
          singular: 'bfdprofile',
        },
        scope: 'Namespaced',
        versions: [
          {
            name: 'v1beta1',
            served: true,
            storage: true,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      receiveInterval: { type: 'integer' },
                      transmitInterval: { type: 'integer' },
                      detectMultiplier: { type: 'integer' },
                      echoMode: { type: 'boolean' },
                      passiveMode: { type: 'boolean' },
                      minimumTtl: { type: 'integer' },
                    },
                  },
                },
              },
            },
          },
        ],
      },
    },

    // Community CRD
    communityCRD: {
      apiVersion: 'apiextensions.k8s.io/v1',
      kind: 'CustomResourceDefinition',
      metadata: {
        name: 'communities.metallb.io',
      },
      spec: {
        group: 'metallb.io',
        names: {
          kind: 'Community',
          listKind: 'CommunityList',
          plural: 'communities',
          singular: 'community',
        },
        scope: 'Namespaced',
        versions: [
          {
            name: 'v1beta1',
            served: true,
            storage: true,
            schema: {
              openAPIV3Schema: {
                type: 'object',
                properties: {
                  spec: {
                    type: 'object',
                    properties: {
                      communities: {
                        type: 'array',
                        items: {
                          type: 'object',
                          properties: {
                            name: { type: 'string' },
                            value: { type: 'string' },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        ],
      },
    },

    // Controller Deployment
    controllerDeployment: k.apps.v1.deployment.new(
      name='controller',
      replicas=1,
      containers=[
        k.core.v1.container.new(
          name='controller',
          image='quay.io/metallb/controller:%s' % this._config.version,
        )
        + k.core.v1.container.withPorts([
          k.core.v1.containerPort.new(7472)
            + k.core.v1.containerPort.withName('monitoring'),
          k.core.v1.containerPort.new(9443)
            + k.core.v1.containerPort.withName('webhook')
            + k.core.v1.containerPort.withProtocol('TCP'),
        ])
        + k.core.v1.container.withArgs([
          '--port=7472',
          '--log-level=info',
          '--webhook-mode=disabled',
        ])
        + k.core.v1.container.securityContext.withAllowPrivilegeEscalation(false)
        + k.core.v1.container.securityContext.capabilities.withDrop(['ALL'])
        + k.core.v1.container.securityContext.withRunAsNonRoot(true)
        + k.core.v1.container.securityContext.withRunAsUser(65534)
        + k.core.v1.container.securityContext.withRunAsGroup(65534),
      ],
    )
    + k.apps.v1.deployment.metadata.withNamespace(this._config.namespace)
    + k.apps.v1.deployment.metadata.withLabels(this._config.labels + { component: 'controller' })
    + k.apps.v1.deployment.spec.selector.withMatchLabels(this._config.labels + { component: 'controller' })
    + k.apps.v1.deployment.spec.template.metadata.withLabels(this._config.labels + { component: 'controller' })
    + k.apps.v1.deployment.spec.template.spec.withServiceAccountName('controller')
    + k.apps.v1.deployment.spec.template.spec.securityContext.withRunAsNonRoot(true)
    + k.apps.v1.deployment.spec.template.spec.securityContext.withRunAsUser(65534)
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

    // Speaker DaemonSet
    speakerDaemonSet: k.apps.v1.daemonSet.new(
      name='speaker',
      containers=[
        k.core.v1.container.new(
          name='speaker',
          image='quay.io/metallb/speaker:%s' % this._config.version,
        )
        + k.core.v1.container.withPorts([
          k.core.v1.containerPort.new(7472)
            + k.core.v1.containerPort.withName('monitoring'),
          k.core.v1.containerPort.new(7946)
            + k.core.v1.containerPort.withName('memberlist-tcp')
            + k.core.v1.containerPort.withProtocol('TCP'),
          k.core.v1.containerPort.new(7946)
            + k.core.v1.containerPort.withName('memberlist-udp')
            + k.core.v1.containerPort.withProtocol('UDP'),
        ])
        + k.core.v1.container.withEnv([
          k.core.v1.envVar.fromFieldPath('METALLB_NODE_NAME', 'spec.nodeName'),
          k.core.v1.envVar.fromFieldPath('METALLB_HOST', 'status.hostIP'),
          k.core.v1.envVar.new('METALLB_ML_BIND_ADDR', '0.0.0.0'),
          k.core.v1.envVar.new('METALLB_ML_LABELS', 'app=metallb,component=speaker'),
          k.core.v1.envVar.fromFieldPath('METALLB_ML_NAMESPACE', 'metadata.namespace'),
          k.core.v1.envVar.new('METALLB_ML_SECRET_KEY_PATH', '/etc/ml_secret_key'),
        ])
        + k.core.v1.container.withArgs([
          '--port=7472',
          '--log-level=info',
        ])
        + k.core.v1.container.securityContext.withAllowPrivilegeEscalation(false)
        + k.core.v1.container.securityContext.capabilities.withDrop(['ALL'])
        + k.core.v1.container.securityContext.capabilities.withAdd(['NET_RAW', 'NET_ADMIN'])
        + k.core.v1.container.withVolumeMounts([
          k.core.v1.volumeMount.new('memberlist', '/etc/ml_secret_key')
            + k.core.v1.volumeMount.withReadOnly(true),
        ]),
      ],
    )
    + k.apps.v1.daemonSet.metadata.withNamespace(this._config.namespace)
    + k.apps.v1.daemonSet.metadata.withLabels(this._config.labels + { component: 'speaker' })
    + k.apps.v1.daemonSet.spec.selector.withMatchLabels(this._config.labels + { component: 'speaker' })
    + k.apps.v1.daemonSet.spec.template.metadata.withLabels(this._config.labels + { component: 'speaker' })
    + k.apps.v1.daemonSet.spec.template.spec.withServiceAccountName('speaker')
    + k.apps.v1.daemonSet.spec.template.spec.withHostNetwork(true)
    + k.apps.v1.daemonSet.spec.template.spec.withTerminationGracePeriodSeconds(2)
    + k.apps.v1.daemonSet.spec.template.spec.withVolumes([
      k.core.v1.volume.fromSecret('memberlist', 'memberlist')
        + k.core.v1.volume.secret.withDefaultMode(420),
    ])
    + k.apps.v1.daemonSet.spec.template.spec.withTolerations([
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

    // ServiceAccount for Controller
    controllerServiceAccount: k.core.v1.serviceAccount.new('controller')
      + k.core.v1.serviceAccount.metadata.withNamespace(this._config.namespace)
      + k.core.v1.serviceAccount.metadata.withLabels(this._config.labels),

    // ServiceAccount for Speaker
    speakerServiceAccount: k.core.v1.serviceAccount.new('speaker')
      + k.core.v1.serviceAccount.metadata.withNamespace(this._config.namespace)
      + k.core.v1.serviceAccount.metadata.withLabels(this._config.labels),

    // ClusterRole for Controller
    controllerClusterRole: k.rbac.v1.clusterRole.new('metallb-system:controller')
      + k.rbac.v1.clusterRole.withRules([
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['services', 'namespaces'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['services/status'])
        + k.rbac.v1.policyRule.withVerbs(['update']),
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['events'])
        + k.rbac.v1.policyRule.withVerbs(['create', 'patch']),
        k.rbac.v1.policyRule.withApiGroups(['metallb.io'])
        + k.rbac.v1.policyRule.withResources(['ipaddresspools', 'l2advertisements', 'bgpadvertisements', 'bgppeers', 'communities'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
        k.rbac.v1.policyRule.withApiGroups(['metallb.io'])
        + k.rbac.v1.policyRule.withResources(['ipaddresspools/status'])
        + k.rbac.v1.policyRule.withVerbs(['update']),
        // Additional permissions for webhook certificate management
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['secrets'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch', 'create', 'update', 'patch']),
        k.rbac.v1.policyRule.withApiGroups(['admissionregistration.k8s.io'])
        + k.rbac.v1.policyRule.withResources(['validatingwebhookconfigurations', 'mutatingwebhookconfigurations'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch', 'create', 'update', 'patch']),
        k.rbac.v1.policyRule.withApiGroups(['apiextensions.k8s.io'])
        + k.rbac.v1.policyRule.withResources(['customresourcedefinitions'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
      ])
      + k.rbac.v1.clusterRole.metadata.withLabels(this._config.labels),

    // ClusterRole for Speaker
    speakerClusterRole: k.rbac.v1.clusterRole.new('metallb-system:speaker')
      + k.rbac.v1.clusterRole.withRules([
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['services', 'endpoints', 'nodes', 'namespaces', 'pods'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['events'])
        + k.rbac.v1.policyRule.withVerbs(['create', 'patch']),
        k.rbac.v1.policyRule.withApiGroups(['discovery.k8s.io'])
        + k.rbac.v1.policyRule.withResources(['endpointslices'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
        k.rbac.v1.policyRule.withApiGroups(['metallb.io'])
        + k.rbac.v1.policyRule.withResources(['ipaddresspools', 'l2advertisements', 'bgpadvertisements', 'bgppeers', 'bfdprofiles', 'communities'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
      ])
      + k.rbac.v1.clusterRole.metadata.withLabels(this._config.labels),

    // Role for Controller (namespace-scoped secrets access for webhook certs)
    controllerRole: k.rbac.v1.role.new('metallb-system:controller')
      + k.rbac.v1.role.metadata.withNamespace(this._config.namespace)
      + k.rbac.v1.role.withRules([
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['secrets'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch', 'create', 'update', 'patch', 'delete']),
      ])
      + k.rbac.v1.role.metadata.withLabels(this._config.labels),

    // RoleBinding for Controller
    controllerRoleBinding: k.rbac.v1.roleBinding.new('metallb-system:controller')
      + k.rbac.v1.roleBinding.metadata.withNamespace(this._config.namespace)
      + k.rbac.v1.roleBinding.bindRole(this.controllerRole)
      + k.rbac.v1.roleBinding.withSubjects([
        k.rbac.v1.subject.fromServiceAccount(this.controllerServiceAccount),
      ])
      + k.rbac.v1.roleBinding.metadata.withLabels(this._config.labels),

    // Role for Speaker (namespace-scoped secrets and configmaps access)
    speakerRole: k.rbac.v1.role.new('metallb-system:speaker')
      + k.rbac.v1.role.metadata.withNamespace(this._config.namespace)
      + k.rbac.v1.role.withRules([
        k.rbac.v1.policyRule.withApiGroups([''])
        + k.rbac.v1.policyRule.withResources(['secrets', 'configmaps'])
        + k.rbac.v1.policyRule.withVerbs(['get', 'list', 'watch']),
      ])
      + k.rbac.v1.role.metadata.withLabels(this._config.labels),

    // RoleBinding for Speaker
    speakerRoleBinding: k.rbac.v1.roleBinding.new('metallb-system:speaker')
      + k.rbac.v1.roleBinding.metadata.withNamespace(this._config.namespace)
      + k.rbac.v1.roleBinding.bindRole(this.speakerRole)
      + k.rbac.v1.roleBinding.withSubjects([
        k.rbac.v1.subject.fromServiceAccount(this.speakerServiceAccount),
      ])
      + k.rbac.v1.roleBinding.metadata.withLabels(this._config.labels),

    // ClusterRoleBindings
    controllerClusterRoleBinding: k.rbac.v1.clusterRoleBinding.new('metallb-system:controller')
      + k.rbac.v1.clusterRoleBinding.bindRole(this.controllerClusterRole)
      + k.rbac.v1.clusterRoleBinding.withSubjects([
        k.rbac.v1.subject.fromServiceAccount(this.controllerServiceAccount),
      ])
      + k.rbac.v1.clusterRoleBinding.metadata.withLabels(this._config.labels),

    speakerClusterRoleBinding: k.rbac.v1.clusterRoleBinding.new('metallb-system:speaker')
      + k.rbac.v1.clusterRoleBinding.bindRole(this.speakerClusterRole)
      + k.rbac.v1.clusterRoleBinding.withSubjects([
        k.rbac.v1.subject.fromServiceAccount(this.speakerServiceAccount),
      ])
      + k.rbac.v1.clusterRoleBinding.metadata.withLabels(this._config.labels),

    // Memberlist Secret
    memberlistSecret: k.core.v1.secret.new('memberlist', {})
      + k.core.v1.secret.metadata.withNamespace(this._config.namespace)
      + k.core.v1.secret.withStringData({
        secretkey: std.base64('changeme12345678'),  // Should be changed in production
      }),

    // Webhook Service
    webhookService: k.core.v1.service.new(
      name='webhook-service',
      selector=this._config.labels + { component: 'controller' },
      ports=[
        k.core.v1.servicePort.new(port=443, targetPort=9443)
          + k.core.v1.servicePort.withName('webhook'),
      ],
    )
    + k.core.v1.service.metadata.withNamespace(this._config.namespace)
    + k.core.v1.service.metadata.withLabels(this._config.labels),
  },

  // Add IP Address Pool configuration
  withIPAddressPool(name, addresses, autoAssign=true):: {
    local this = self,
    local poolLabels = { 'metallb.io/pool': name },

    ['ipAddressPool_%s' % name]: {
      apiVersion: 'metallb.io/v1beta1',
      kind: 'IPAddressPool',
      metadata: {
        name: name,
        namespace: this._config.namespace,
        labels: this._config.labels,
      },
      spec: {
        addresses: if std.isArray(addresses) then addresses else [addresses],
        autoAssign: autoAssign,
      },
    },
  },

  // Add L2 Advertisement
  withL2Advertisement(name, ipAddressPools=[]):: {
    local this = self,

    ['l2Advertisement_%s' % name]: {
      apiVersion: 'metallb.io/v1beta1',
      kind: 'L2Advertisement',
      metadata: {
        name: name,
        namespace: this._config.namespace,
        labels: this._config.labels,
      },
      spec: {
        ipAddressPools: ipAddressPools,
      },
    },
  },
}
