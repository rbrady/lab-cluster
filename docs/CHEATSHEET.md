# Tanka & Jsonnet Cheat Sheet

Quick reference for common patterns and commands when working with Tanka and Jsonnet.

## Tanka Commands

### Basic Operations
```bash
# Show rendered manifests
tk show environments/mini-01

# Show as YAML
tk show environments/mini-01 --format=yaml

# Show diff against cluster
tk diff environments/mini-01

# Apply to cluster
tk apply environments/mini-01

# Apply with auto-approval (be careful!)
tk apply environments/mini-01 --dangerous-auto-approve

# Apply allowing redirects (when kubeconfig context doesn't match exactly)
tk apply environments/mini-01 --dangerous-allow-redirect

# Delete all resources
tk delete environments/mini-01

# Prune removed resources (requires injectLabels: true)
tk prune environments/mini-01

# Export to YAML files
tk export environments/mini-01 output/
```

### Environment Management
```bash
# List all environments
tk env list

# Create new environment
tk env add environments/staging \
  --server=https://<kubectl-address>:6443 \
  --namespace=staging

# Update environment settings
tk env set environments/mini-01 --namespace=production

# Remove environment
tk env remove environments/old-env
```

### Dependency Management
```bash
# Install dependencies
jb install

# Add new dependency
jb install github.com/grafana/jsonnet-libs/prometheus

# Update dependencies
jb update

# List installed packages
jb list
```

## Jsonnet Patterns

### Basic Imports
```jsonnet
// Import k8s library
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';

// Import local library
local myapp = import 'myapp.libsonnet';

// Import from vendor
local prometheus = import 'prometheus/prometheus.libsonnet';
```

### Configuration Pattern
```jsonnet
{
  _config:: {
    namespace: 'default',
    replicas: 3,
    image: 'myapp:v1.0.0',
    port: 8080,
  },

  deployment: /* use _config here */,
}
```

### Creating a Deployment
```jsonnet
local k = import 'k.libsonnet';

k.apps.v1.deployment.new(
  name='myapp',
  replicas=3,
  containers=[
    k.core.v1.container.new(
      name='app',
      image='nginx:latest',
    )
    + k.core.v1.container.withPorts([
      k.core.v1.containerPort.new('http', 80),
    ]),
  ],
)
+ k.apps.v1.deployment.metadata.withLabels({ app: 'myapp' })
+ k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'myapp' })
+ k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'myapp' })
```

### Creating a Service
```jsonnet
k.core.v1.service.new(
  name='myapp',
  selector={ app: 'myapp' },
  ports=[
    k.core.v1.servicePort.new(
      name='http',
      port=80,
      targetPort=8080,
    ),
  ],
)
+ k.core.v1.service.spec.withType('ClusterIP')
```

### ConfigMap
```jsonnet
k.core.v1.configMap.new(
  name='myapp-config',
  data={
    'config.yaml': |||
      server:
        port: 8080
        host: 0.0.0.0
    |||,
    'feature-flags.json': std.manifestJsonEx({
      features: {
        newUI: true,
        betaAPI: false,
      },
    }, '  '),
  },
)
```

### Secret
```jsonnet
k.core.v1.secret.new(
  name='myapp-secret',
  data={
    username: std.base64('admin'),
    password: std.base64('supersecret'),
  },
)
+ k.core.v1.secret.withType('Opaque')
```

### Environment Variables
```jsonnet
// Simple env vars
k.core.v1.container.withEnv([
  k.core.v1.envVar.new('PORT', '8080'),
  k.core.v1.envVar.new('ENV', 'production'),
])

// From ConfigMap
k.core.v1.container.withEnvFrom([
  k.core.v1.envFromSource.configMapRef.withName('myapp-config'),
])

// From Secret
k.core.v1.container.withEnv([
  k.core.v1.envVar.fromSecretRef('DB_PASSWORD', 'db-secret', 'password'),
])
```

### Volume Mounts
```jsonnet
// In container
k.core.v1.container.withVolumeMounts([
  k.core.v1.volumeMount.new('config', '/etc/config'),
  k.core.v1.volumeMount.new('data', '/data'),
])

// In pod spec
k.apps.v1.deployment.spec.template.spec.withVolumes([
  k.core.v1.volume.fromConfigMap('config', 'myapp-config'),
  k.core.v1.volume.fromPersistentVolumeClaim('data', 'myapp-pvc'),
])
```

### Resource Limits
```jsonnet
k.core.v1.container.resources.withRequests({
  cpu: '100m',
  memory: '128Mi',
})
+ k.core.v1.container.resources.withLimits({
  cpu: '500m',
  memory: '512Mi',
})
```

### Health Checks
```jsonnet
// Liveness probe
k.core.v1.container.withLivenessProbe(
  k.core.v1.probe.httpGet.withPath('/healthz')
  + k.core.v1.probe.httpGet.withPort('http')
  + k.core.v1.probe.withInitialDelaySeconds(30)
  + k.core.v1.probe.withPeriodSeconds(10)
  + k.core.v1.probe.withTimeoutSeconds(5)
)

// Readiness probe
k.core.v1.container.withReadinessProbe(
  k.core.v1.probe.httpGet.withPath('/ready')
  + k.core.v1.probe.httpGet.withPort('http')
  + k.core.v1.probe.withInitialDelaySeconds(5)
  + k.core.v1.probe.withPeriodSeconds(5)
)

// TCP probe
k.core.v1.probe.tcpSocket.withPort(8080)

// Command probe
k.core.v1.probe.exec.withCommand(['/bin/sh', '-c', 'test -f /tmp/healthy'])
```

### Ingress
```jsonnet
k.networking.v1.ingress.new('myapp')
+ k.networking.v1.ingress.metadata.withAnnotations({
  'kubernetes.io/ingress.class': 'nginx',
  'cert-manager.io/cluster-issuer': 'letsencrypt-prod',
})
+ k.networking.v1.ingress.spec.withRules([
  k.networking.v1.ingressRule.withHost('app.example.com')
  + k.networking.v1.ingressRule.http.withPaths([
    k.networking.v1.httpIngressPath.withPath('/')
    + k.networking.v1.httpIngressPath.withPathType('Prefix')
    + k.networking.v1.httpIngressPath.backend.service.withName('myapp')
    + k.networking.v1.httpIngressPath.backend.service.port.withNumber(80),
  ]),
])
+ k.networking.v1.ingress.spec.withTls([
  k.networking.v1.ingressTLS.withHosts(['app.example.com'])
  + k.networking.v1.ingressTLS.withSecretName('app-tls'),
])
```

### StatefulSet
```jsonnet
k.apps.v1.statefulSet.new(
  name='myapp',
  replicas=3,
  containers=[
    k.core.v1.container.new('app', 'myapp:latest'),
  ],
  volumeClaims=[
    k.core.v1.persistentVolumeClaim.new('data')
    + k.core.v1.persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce'])
    + k.core.v1.persistentVolumeClaim.spec.resources.withRequests({
      storage: '10Gi',
    }),
  ],
)
+ k.apps.v1.statefulSet.spec.withServiceName('myapp')
```

### CronJob
```jsonnet
k.batch.v1.cronJob.new(
  name='backup',
  schedule='0 2 * * *',
  containers=[
    k.core.v1.container.new('backup', 'backup:latest')
    + k.core.v1.container.withCommand(['/backup.sh']),
  ],
)
+ k.batch.v1.cronJob.spec.withSuccessfulJobsHistoryLimit(3)
+ k.batch.v1.cronJob.spec.withFailedJobsHistoryLimit(1)
+ k.batch.v1.cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('OnFailure')
```

### Job
```jsonnet
k.batch.v1.job.new(
  name='migration',
  containers=[
    k.core.v1.container.new('migrate', 'migrate:latest'),
  ],
)
+ k.batch.v1.job.spec.withBackoffLimit(3)
+ k.batch.v1.job.spec.template.spec.withRestartPolicy('Never')
```

## Jsonnet Language

### Variables
```jsonnet
local replicas = 3;
local image = 'nginx:latest';
```

### Objects
```jsonnet
{
  name: 'myapp',
  replicas: 3,
  nested: {
    key: 'value',
  },
}
```

### Arrays
```jsonnet
local ports = [80, 443, 8080];
local containers = [
  { name: 'app1', image: 'app1:latest' },
  { name: 'app2', image: 'app2:latest' },
];
```

### String Interpolation
```jsonnet
local name = 'myapp';
{
  fullName: '%s-deployment' % name,
  message: 'Hello, %(name)s!' % { name: name },
}
```

### Multi-line Strings
```jsonnet
{
  config: |||
    line 1
    line 2
    line 3
  |||,
}
```

### Conditionals
```jsonnet
{
  replicas: if env == 'prod' then 5 else 1,

  // Conditional fields
  [if enableFeature then 'feature']: 'enabled',
}
```

### Functions
```jsonnet
local multiply(x, y) = x * y;

local createContainer(name, image) = {
  name: name,
  image: image,
};

{
  result: multiply(3, 4),
  container: createContainer('app', 'nginx:latest'),
}
```

### Array Comprehension
```jsonnet
local names = ['app1', 'app2', 'app3'];

{
  containers: [
    { name: name, image: '%s:latest' % name }
    for name in names
  ],

  // With condition
  filtered: [
    x * 2
    for x in std.range(1, 10)
    if x % 2 == 0
  ],
}
```

### Object Composition
```jsonnet
local base = {
  name: 'myapp',
  replicas: 1,
};

{
  // Merge
  dev: base { replicas: 2 },

  // Deep merge with +
  prod: base {
    replicas: 5,
    metadata+: {
      labels: { env: 'prod' },
    },
  },
}
```

### Standard Library Functions
```jsonnet
// String functions
std.length('hello')              // 5
std.substr('hello', 0, 4)        // 'hell'
std.startsWith('hello', 'hel')   // true
std.split('a,b,c', ',')          // ['a', 'b', 'c']
std.join(',', ['a', 'b', 'c'])   // 'a,b,c'
std.format('%s-%d', ['app', 1])  // 'app-1'

// Array functions
std.length([1, 2, 3])            // 3
std.map(function(x) x * 2, [1, 2, 3])  // [2, 4, 6]
std.filter(function(x) x > 2, [1, 2, 3, 4])  // [3, 4]
std.foldl(function(x, y) x + y, [1, 2, 3], 0)  // 6
std.flattenArrays([[1, 2], [3, 4]])  // [1, 2, 3, 4]
std.reverse([1, 2, 3])           // [3, 2, 1]
std.sort([3, 1, 2])              // [1, 2, 3]

// Object functions
std.objectFields({ a: 1, b: 2 })  // ['a', 'b']
std.objectHas({ a: 1 }, 'a')      // true
std.objectValues({ a: 1, b: 2 })  // [1, 2]

// Type functions
std.type('hello')                // 'string'
std.type(123)                    // 'number'
std.type([])                     // 'array'
std.type({})                     // 'object'

// Encoding
std.base64('hello')              // base64 encoded
std.base64Decode('aGVsbG8=')     // 'hello'
std.manifestJsonEx({ a: 1 }, '  ')  // pretty JSON
std.manifestYamlDoc({ a: 1 })    // YAML output

// Math
std.max(1, 5, 3)                 // 5
std.min(1, 5, 3)                 // 1
std.floor(3.7)                   // 3
std.ceil(3.2)                    // 4
std.abs(-5)                      // 5
```

## Common Patterns

### Mixins Pattern
```jsonnet
local k = import 'k.libsonnet';

{
  new(name, image):: {
    deployment: k.apps.v1.deployment.new(name, 1, [
      k.core.v1.container.new(name, image),
    ]),
  },

  withReplicas(replicas):: {
    deployment+: k.apps.v1.deployment.spec.withReplicas(replicas),
  },

  withPort(port):: {
    deployment+: /* add port */,
    service: /* create service */,
  },
}

// Usage:
myapp.new('app', 'nginx:latest')
+ myapp.withReplicas(3)
+ myapp.withPort(80)
```

### Multi-Environment Pattern
```jsonnet
local base = {
  name: 'myapp',
  image: 'myapp:latest',
};

{
  dev: base {
    replicas: 1,
    resources: { /* small */ },
  },

  prod: base {
    replicas: 5,
    resources: { /* large */ },
  },
}
```

### Utility Functions
```jsonnet
local utils = {
  // Generate labels
  labels(name, component='app'):: {
    app: name,
    component: component,
    'app.kubernetes.io/name': name,
    'app.kubernetes.io/component': component,
  },

  // Common annotations
  annotations(metrics=true):: {
    [if metrics then 'prometheus.io/scrape']: 'true',
    [if metrics then 'prometheus.io/port']: '9090',
  },

  // Standard probes
  httpProbe(path, port, initial=10, period=10)::
    k.core.v1.probe.httpGet.withPath(path)
    + k.core.v1.probe.httpGet.withPort(port)
    + k.core.v1.probe.withInitialDelaySeconds(initial)
    + k.core.v1.probe.withPeriodSeconds(period),
};
```

## Troubleshooting

### View Jsonnet Evaluation
```bash
# Evaluate jsonnet file
jsonnet environments/mini-01/main.jsonnet

# Pretty print
jsonnet -S environments/mini-01/main.jsonnet

# Multi-file output
jsonnet -m output/ environments/mini-01/main.jsonnet
```

### Validate Syntax
```bash
# Check syntax
jsonnet --version  # If this works, basic syntax is ok

# Use tanka
tk show environments/mini-01 > /dev/null && echo "Valid!"
```

### Debug Output
```jsonnet
// Add debug fields
{
  _debug:: {
    config: self._config,
    // Will not be rendered to YAML
  },

  // Or use error to stop and show value
  // error std.manifestJsonEx(self._config, '  '),
}
```

### Format Code
```bash
# Format in-place
jsonnetfmt -i file.jsonnet

# Format all files
find . -name "*.jsonnet" -o -name "*.libsonnet" | xargs -I {} jsonnetfmt -i {}
```

## Quick Reference Card

| Command | Description |
|---------|-------------|
| `tk show ENV` | Preview manifests |
| `tk diff ENV` | Show diff with cluster |
| `tk apply ENV` | Deploy to cluster |
| `tk delete ENV` | Delete resources |
| `jb install` | Install dependencies |
| `make show` | Preview (via Makefile) |
| `make apply` | Deploy (via Makefile) |
| `k.apps.v1.deployment.new()` | Create deployment |
| `k.core.v1.service.new()` | Create service |
| `k.core.v1.configMap.new()` | Create configmap |
| `std.manifestJsonEx()` | Pretty JSON |
| `std.base64()` | Base64 encode |
| `+ object` | Deep merge |
| `{ field: value }` | Shallow merge |

## Resources

- **Tanka**: https://tanka.dev/
- **Jsonnet**: https://jsonnet.org/
- **k8s-libsonnet**: https://github.com/jsonnet-libs/k8s-libsonnet
- **Jsonnet style guide**: https://jsonnet.org/ref/style.html
- **Standard library**: https://jsonnet.org/ref/stdlib.html
