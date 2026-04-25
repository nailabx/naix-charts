# naix-charts

Helm charts maintained by Nailabx, published as a public Helm repository
at <https://nailabx.github.io/naix-charts>.

## Charts

| Chart | Description |
|---|---|
| [`stateless`](charts/stateless/) | Universal chart for stateless Kubernetes workloads — Deployment + opt-in feature blocks for Service, Ingress, Gateway API HTTPRoute, APIsix PluginConfig, ConfigMap, ExternalSecret (ESO), HPA, KEDA ScaledObject, PodDisruptionBudget, NetworkPolicy, PodMonitor, ServiceMonitor. |
| [`nodepool`](charts/nodepool/) | Karpenter `NodePool` + `EC2NodeClass` pairs with sensible defaults for AWS EKS. |

## Install

```bash
helm repo add nailabx https://nailabx.github.io/naix-charts
helm repo update

# Use a chart
helm install my-app nailabx/stateless --version 1.0.0 -f my-values.yaml
```

## Versioning

Each chart follows semver independently:

- Patch (1.0.x) — bug fixes, internal refactors
- Minor (1.x.0) — additive features, new optional fields
- Major (x.0.0) — breaking values changes

Release pipeline (`.github/workflows/release.yml`) builds + publishes on
tag push: `git tag <chart>-<version>` (e.g. `stateless-1.0.0`).

## Contributing

```bash
# Lint
helm lint charts/<chart>

# Render against an example values file
helm template my-app charts/<chart> -f charts/<chart>/values-examples/<example>.yaml

# Manual install in a kind cluster for testing
helm install my-app charts/<chart> -f my-values.yaml
```

## License

MIT.
