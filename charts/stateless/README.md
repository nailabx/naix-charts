# stateless

Universal Helm chart for stateless Kubernetes workloads. Renders one or
more containers with **opt-in feature blocks** for routing, config,
secrets, autoscaling, resilience, and observability. Works equally well
as a one-liner nginx deployment or a fully-wired microservice behind a
shared gateway.

## TL;DR

```bash
helm repo add nailabx https://nailabx.github.io/naix-charts
helm install my-app nailabx/stateless \
  --set containers.app.image.repository=nginx \
  --set containers.app.image.tag=1.25
```

## Why this chart

`helm create` gives you a single-container Deployment + Service + Ingress
+ HPA. Real apps need more: secrets, multi-container pods, Gateway API,
KEDA, PodMonitor. Most teams either copy `helm create` and bolt on what
they need (drift across services) or import a heavyweight common chart
(Bitnami's). This chart is in between: **opinionated defaults +
feature flags** for the resources teams actually use.

Every feature block defaults to `enabled: false`. Add `<feature>.enabled:
true` only for what you use.

## Feature blocks

| Block | Renders | Use when |
|---|---|---|
| `containers` (required) | Deployment containers (map, supports sidecars) | Always |
| `service` | k8s Service (ClusterIP/NodePort/LB) | Almost always — flip off for pure workers |
| `ingress` | k8s `Ingress` | Cluster doesn't have Gateway API |
| `gatewayApi` | `HTTPRoute` + optional `ReferenceGrant` | Cluster has Gateway API (any impl) |
| `apisix` | APIsix `PluginConfig` (per-route plugins) | APIsix is your Gateway API impl |
| `configMap` | `ConfigMap` (mounted as env or files) | Non-secret config |
| `externalSecret` | ESO `ExternalSecret` (synced from AWS Secrets Manager / Vault / etc.) | Cluster has External Secrets Operator |
| `existingSecrets` / `existingConfigMaps` | envFrom on existing resources | BYO secrets / configmaps |
| `hpa` | HorizontalPodAutoscaler (CPU + memory + custom metrics) | Standard reactive autoscaling |
| `scaledObject` | KEDA `ScaledObject` (event-driven, scale-to-zero) | Cluster has KEDA, want better triggers |
| `podDisruptionBudget` | `PodDisruptionBudget` | Production HA |
| `podMonitor` | Prometheus Operator `PodMonitor` | kube-prometheus-stack installed |
| `serviceMonitor` | Prometheus Operator `ServiceMonitor` | Same, via Service |
| `networkPolicy` | `NetworkPolicy` | Restrict pod-to-pod traffic |

## Examples

The `values-examples/` directory has annotated values files for the
common patterns:

- **`simple-nginx.yaml`** — minimum viable deployment (3 lines)
- **`microservice-apisix.yaml`** — Go service behind APIsix + Firebase OIDC + ESO secrets
- **`keda-worker.yaml`** — background worker scaling to zero off-hours
- **`multi-container-with-sidecar.yaml`** — app + OpenTelemetry collector sidecar

Try one out:

```bash
helm template my-app nailabx/stateless -f values-examples/simple-nginx.yaml
```

## Multi-container layout

`containers:` is a map (not array) so individual container values can
be overridden via `--set containers.app.image.tag=v2`. The first key
alphabetically is treated as primary for service-port resolution.

```yaml
containers:
  app:                     # primary
    image: { repository: my-app, tag: "1.0" }
    ports: [{ name: http, containerPort: 8080 }]
  otel-collector:          # sidecar
    image: { repository: otel/opentelemetry-collector }
    ports: [{ name: otlp, containerPort: 4317 }]
```

`initContainers:` is an array (order matters for sequential init).

## envFrom auto-mounting

When `configMap.mountAsEnv: true` (default) and/or
`externalSecret.mountAsEnv: true` (default), every container in the map
automatically gets `envFrom: [configMapRef, secretRef]` pointing at the
synced resources. No manual wiring.

For containers that should NOT get the auto-mount (e.g., a sidecar that
shouldn't see the app's secrets), set `containers.<name>.extraEnvFrom`
explicitly and consider whether the auto-mount is right for your case.

## Service port naming

Services use **named target ports** that resolve across all containers.
Define a port name on a container (`ports[].name: http`), reference it
in `service.ports[].targetPort: http`. Works regardless of which
container exposes the port.

## Files in this chart

```
charts/stateless/
├── Chart.yaml
├── values.yaml              ← all feature blocks documented
├── README.md                ← this file
├── values-examples/         ← annotated example value files
└── templates/
    ├── _helpers.tpl
    ├── NOTES.txt
    ├── workload/            ← deployment, serviceaccount, pdb
    ├── network/             ← service, ingress, httproute, referencegrant, pluginconfig, networkpolicy
    ├── config/              ← configmap, externalsecret
    ├── scaling/             ← hpa, scaledobject
    ├── observability/       ← podmonitor, servicemonitor
    └── tests/               ← helm test connection
```

## Compatibility

- Helm: ≥3.14
- Kubernetes: ≥1.27 (Gateway API GA in 1.30; chart degrades gracefully if not installed)
- CRDs the chart renders (when enabled) — must be installed in cluster:
  - `gateway.networking.k8s.io/v1` HTTPRoute / ReferenceGrant — Gateway API
  - `external-secrets.io/v1` ExternalSecret — External Secrets Operator
  - `monitoring.coreos.com/v1` PodMonitor / ServiceMonitor — Prometheus Operator
  - `keda.sh/v1alpha1` ScaledObject — KEDA
  - `apisix.apache.org/v1alpha1` PluginConfig — APIsix Ingress Controller

## Migration from chart v0.x

Breaking changes in v1.0.0:

| v0.x value | v1.x value |
|---|---|
| `image.repository`, `image.tag`, `image.pullPolicy` | `containers.app.image.{repository,tag,pullPolicy}` |
| `resources` | `containers.app.resources` |
| `livenessProbe`, `readinessProbe` | `containers.app.livenessProbe`, `containers.app.readinessProbe` |
| `volumeMounts` | `containers.app.volumeMounts` |
| `securityContext` | `containers.app.securityContext` |
| `autoscaling.enabled` (HPA) | `hpa.enabled` |
| `service.port` (single value) | `service.ports[]` (array) |
| `ingress.enabled` | unchanged — but path-based config schema changed |

Migrate by moving image/resources/probes under `containers.app.*` and
swapping `autoscaling` → `hpa`. The chart itself doesn't error on the
old keys — they're just silently ignored. A future v2.x will fail fast.

## License

MIT.
