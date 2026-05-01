# Changelog — `stateless`

All notable changes to this chart, newest first. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning is
[semver](https://semver.org/) (patch = bug fixes, minor = additive,
major = breaking values changes).

## [1.1.2] — 2026-04-30

### Removed

- `templates/network/apisixroute.yaml` (introduced in 1.1.0). The template
  emitted an `apisix.apache.org/v2 ApisixRoute` for services that
  needed WebSocket support that Gateway API HTTPRoute couldn't express
  through `apisix-ingress-controller` v2.0.1. Two reasons it was
  reverted:
  1. **Architecturally wrong direction** — Nailabx clusters are
     Gateway-API-only by policy. ApisixRoute is the legacy alternative-
     to-Gateway-API CRD we explicitly steer away from.
  2. **It didn't work anyway** — `apisix-ingress-controller` v2.0.1's
     reconciler is a no-op for `ApisixRoute` v2 (and `ApisixPluginConfig`
     v2; per upstream PR #2745 they're "status-only" controllers).
     Webhook accepts the resource and writes status, but never pushes
     to APIsix etcd.

### Notes

This release is byte-for-byte identical to **1.0.1** except for the
`Chart.yaml` version field. Existing 1.0.1 consumers don't need to
upgrade — bump opportunistically when a future chart change actually
needs it.

The right path for HTTPRoute + WebSocket is **`Service.spec.ports[].appProtocol: kubernetes.io/ws`**
(or `kubernetes.io/wss`). The `apisix-ingress-controller` v2 HTTPRoute
translator reads `port.AppProtocol` from the backend Service and sets
`enable_websocket=true` on the resulting APIsix route. Standard K8s
field, Gateway-API-clean, no chart change needed.

## [1.1.1] — 2026-04-30 _(skip — superseded by 1.1.2)_

### Fixed

- `apisixRoute` template: set `spec.ingressClassName` (default `apisix`)
  so the `apisix-ingress-controller` v2 actually reconciles it. Without
  this, the resource was webhook-accepted but never picked up.

### Notes

The fix worked at the K8s layer (resource validated and tracked) but
the underlying reconciler in `apisix-ingress-controller` v2.0.1 doesn't
push `ApisixRoute` to APIsix etcd anyway, so this version doesn't
deliver functional WebSocket support. Reverted in 1.1.2. **Skip
directly from 1.0.1 → 1.1.2.**

## [1.1.0] — 2026-04-30 _(skip — superseded by 1.1.2)_

### Added

- `templates/network/apisixroute.yaml` template that emits an
  `apisix.apache.org/v2 ApisixRoute` with per-rule `websocket: true`
  support. Intended as an escape hatch for WebSocket on
  `apisix-ingress-controller` v2.0.1, where Gateway API HTTPRoute
  appeared to lack `enable_websocket` propagation.

### Notes

Reverted in 1.1.2 (see above). **Skip directly from 1.0.1 → 1.1.2.**

## [1.0.1] — 2026-04-25

### Fixed

- `Chart.yaml` `kubeVersion`: bumped lower bound to `>=1.27.0-0`. The
  `-0` suffix is intentional — it tells Helm's semver constraint to
  accept pre-release suffixes (e.g. EKS reports cluster versions like
  `1.35.3-eks-bbe087e`, which without `-0` fails the constraint
  because Helm orders pre-releases below their release counterparts).

## [1.0.0] — 2026-04-25

### Added

- Initial 1.x release. Universal chart for stateless Kubernetes
  workloads with opt-in feature blocks:
  - `containers` (multi-container Deployment)
  - `service` (k8s Service)
  - `ingress` (k8s Ingress)
  - `gatewayApi` (Gateway API `HTTPRoute` + optional `ReferenceGrant`)
  - `apisix` (APIsix `PluginConfig` per route)
  - `configMap`, `externalSecret`
  - `hpa`, `keda`
  - `pdb`, `networkPolicy`
  - `podMonitor`, `serviceMonitor`

### Notes

Supersedes the 0.1.x line; 0.1.x carried bigger restructuring debt and
should not be consumed by new releases.

## [0.1.x] — 2025-09-21 / 2025-09-22 _(historical)_

Early development. Use 1.0.0+ instead.
