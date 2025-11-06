local k = import 'k.libsonnet';

{
  // Additional RBAC for Prometheus to access kubelet metrics
  // This creates a binding to the system:monitoring ClusterRole

  clusterRoleBinding: k.rbac.v1.clusterRoleBinding.new('prometheus-kubelet-metrics')
                      + k.rbac.v1.clusterRoleBinding.metadata.withLabels({
                        app: 'prometheus',
                        component: 'monitoring',
                      })
                      + k.rbac.v1.clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io')
                      + k.rbac.v1.clusterRoleBinding.roleRef.withKind('ClusterRole')
                      + k.rbac.v1.clusterRoleBinding.roleRef.withName('system:monitoring')
                      + k.rbac.v1.clusterRoleBinding.withSubjects([
                        {
                          kind: 'ServiceAccount',
                          name: 'prometheus',
                          namespace: 'monitoring',
                        },
                      ]),
}
