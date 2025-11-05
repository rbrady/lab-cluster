local myapp = import 'myapp.libsonnet';

{
  new():: myapp.new(
    name='nginx-example',
    image='nginxdemos/hello:latest',
    replicas=2,
    port=80,
  )
  + myapp.withServiceType('ClusterIP'),
}
