// This file contains example applications demonstrating various features
// To use these examples, import them in main.jsonnet like:
//   local examples = import 'examples.jsonnet';
//   { myapp: examples.simpleWebApp }

local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';
local myapp = import 'myapp.libsonnet';
local webapp = import 'webapp.libsonnet';

{
  // Example 1: Simple nginx deployment
  simpleNginx:: myapp.new(
    name='simple-nginx',
    image='nginx:alpine',
    replicas=1,
    port=80,
  ),

  // Example 2: Nginx with multiple replicas and LoadBalancer
  scaledNginx:: myapp.new(
    name='scaled-nginx',
    image='nginxdemos/hello:latest',
    replicas=3,
    port=80,
  )
  + myapp.withServiceType('LoadBalancer'),

  // Example 3: Simple web app with ConfigMap
  simpleWebApp:: webapp.new(
    name='demo-webapp',
    image='nginxdemos/hello:latest',
  )
  + webapp.withReplicas(2)
  + webapp.withPort(80),

  // Example 4: Full-featured web application
  fullFeaturedApp:: webapp.new(
    name='api-service',
    image='your-registry/api:v1.0.0',
  )
  + webapp.withReplicas(3)
  + webapp.withPort(8080)
  + webapp.withServiceType('ClusterIP')
  + webapp.withEnv({
    ENV: 'production',
    LOG_LEVEL: 'info',
    DATABASE_HOST: 'postgres.default.svc.cluster.local',
  })
  + webapp.withResources(
    requests={ cpu: '200m', memory: '256Mi' },
    limits={ cpu: '1000m', memory: '1Gi' },
  )
  + webapp.withReadinessProbe('/health')
  + webapp.withLivenessProbe('/health'),

  // Example 5: Web app with Ingress
  webAppWithIngress:: webapp.new(
    name='web-frontend',
    image='your-registry/frontend:v1.0.0',
  )
  + webapp.withReplicas(2)
  + webapp.withPort(3000)
  + webapp.withIngress('app.mini-01.bobcat-ph.ts.net', path='/'),

  // Example 6: Multiple environments (dev/staging/prod) pattern
  environments:: {
    local base = webapp.new(
      name='myapp',
      image='your-registry/myapp:latest',
    ),

    dev:: base
      + webapp.withReplicas(1)
      + webapp.withEnv({ ENV: 'development' })
      + webapp.withResources(
        requests={ cpu: '50m', memory: '64Mi' },
        limits={ cpu: '200m', memory: '256Mi' },
      ),

    staging:: base
      + webapp.withReplicas(2)
      + webapp.withEnv({ ENV: 'staging' })
      + webapp.withResources(
        requests={ cpu: '100m', memory: '128Mi' },
        limits={ cpu: '500m', memory: '512Mi' },
      ),

    prod:: base
      + webapp.withReplicas(5)
      + webapp.withEnv({ ENV: 'production' })
      + webapp.withResources(
        requests={ cpu: '200m', memory: '256Mi' },
        limits={ cpu: '2000m', memory: '2Gi' },
      )
      + webapp.withReadinessProbe('/health')
      + webapp.withLivenessProbe('/health'),
  },

  // Example 7: StatefulSet with headless service
  statefulApp:: {
    local this = self,
    local name = 'stateful-app',
    local labels = { app: name },

    statefulSet: k.apps.v1.statefulSet.new(
      name=name,
      replicas=3,
      containers=[
        k.core.v1.container.new(
          name=name,
          image='your-registry/stateful:latest',
        )
        + k.core.v1.container.withPorts([
          k.core.v1.containerPort.new('http', 8080),
        ])
        + k.core.v1.container.withVolumeMounts([
          k.core.v1.volumeMount.new('data', '/data'),
        ]),
      ],
      volumeClaims=[
        k.core.v1.persistentVolumeClaim.new('data')
        + k.core.v1.persistentVolumeClaim.spec.withAccessModes(['ReadWriteOnce'])
        + k.core.v1.persistentVolumeClaim.spec.resources.withRequests({
          storage: '10Gi',
        }),
      ],
    )
    + k.apps.v1.statefulSet.metadata.withLabels(labels)
    + k.apps.v1.statefulSet.spec.selector.withMatchLabels(labels)
    + k.apps.v1.statefulSet.spec.template.metadata.withLabels(labels)
    + k.apps.v1.statefulSet.spec.withServiceName('stateful-app'),

    service: k.core.v1.service.new(
      name=name,
      selector=labels,
      ports=[
        k.core.v1.servicePort.new('http', 8080, 8080),
      ],
    )
    + k.core.v1.service.spec.withClusterIP('None'),  // Headless service
  },

  // Example 8: CronJob
  cronJobExample:: {
    local name = 'backup-job',
    local labels = { app: name, type: 'cronjob' },

    cronJob: k.batch.v1.cronJob.new(
      name=name,
      schedule='0 2 * * *',  // Run at 2 AM daily
      containers=[
        k.core.v1.container.new(
          name='backup',
          image='your-registry/backup:latest',
        )
        + k.core.v1.container.withCommand([
          '/bin/sh',
          '-c',
          'echo "Running backup..."; /app/backup.sh',
        ])
        + k.core.v1.container.withEnv([
          k.core.v1.envVar.new('BACKUP_DESTINATION', 's3://my-bucket/backups'),
        ]),
      ],
    )
    + k.batch.v1.cronJob.metadata.withLabels(labels)
    + k.batch.v1.cronJob.spec.jobTemplate.spec.template.metadata.withLabels(labels)
    + k.batch.v1.cronJob.spec.withSuccessfulJobsHistoryLimit(3)
    + k.batch.v1.cronJob.spec.withFailedJobsHistoryLimit(1),
  },

  // Example 9: Job (one-time task)
  jobExample:: {
    local name = 'migration-job',
    local labels = { app: name, type: 'job' },

    job: k.batch.v1.job.new(
      name=name,
      containers=[
        k.core.v1.container.new(
          name='migration',
          image='your-registry/migrations:latest',
        )
        + k.core.v1.container.withCommand([
          '/app/run-migrations.sh',
        ]),
      ],
    )
    + k.batch.v1.job.metadata.withLabels(labels)
    + k.batch.v1.job.spec.template.metadata.withLabels(labels)
    + k.batch.v1.job.spec.withBackoffLimit(3)
    + k.batch.v1.job.spec.template.spec.withRestartPolicy('Never'),
  },

  // Example 10: Namespace with ResourceQuota
  namespaceExample:: {
    namespace: k.core.v1.namespace.new('my-namespace')
      + k.core.v1.namespace.metadata.withLabels({
        environment: 'production',
        team: 'platform',
      }),

    resourceQuota: k.core.v1.resourceQuota.new('my-namespace-quota')
      + k.core.v1.resourceQuota.metadata.withNamespace('my-namespace')
      + k.core.v1.resourceQuota.spec.withHard({
        'requests.cpu': '10',
        'requests.memory': '20Gi',
        'limits.cpu': '20',
        'limits.memory': '40Gi',
        'persistentvolumeclaims': '10',
      }),
  },
}
