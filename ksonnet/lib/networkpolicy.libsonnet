local k = import 'k.libsonnet';

{
  // Creates a permissive NetworkPolicy that allows all ingress and egress traffic
  // This is needed when kube-router runs with --run-firewall=true but you want
  // to allow all pod-to-pod communication by default
  allowAll(name='allow-all', namespace='default'):: {
    local this = self,

    networkPolicy: k.networking.v1.networkPolicy.new(name)
      + k.networking.v1.networkPolicy.metadata.withNamespace(namespace)
      + k.networking.v1.networkPolicy.spec.withPolicyTypes(['Ingress', 'Egress'])
      + k.networking.v1.networkPolicy.spec.withIngress([{}])  // Empty ingress rule = allow all
      + k.networking.v1.networkPolicy.spec.withEgress([{}])  // Empty egress rule = allow all
      + {
        spec+: {
          podSelector: {},  // Empty selector = all pods
        },
      },
  },
}
