# kranix-charts

> Helm charts — install the full Kranix platform on Kubernetes in one command.

`kranix-charts` contains the official Helm charts for deploying the Kranix platform to a Kubernetes cluster. It packages `kranix-api`, `kranix-core`, `kranix-operator`, `kranix-mcp`, and their dependencies into a single, configurable release. This is the recommended way to run Kranix in any environment beyond local development.

---

## What it does

- Packages all Kranix components into a single Helm release
- Manages CRD installation alongside the application charts
- Provides sane defaults with full configurability via `values.yaml`
- Supports multi-environment patterns (dev, staging, production overlays)
- Includes RBAC, ServiceAccounts, NetworkPolicies, and PodDisruptionBudgets
- Supports optional components (kranix-mcp, metrics, ingress) via feature flags

---

## Architecture position

```
Helm CLI  ──►  kranix-charts
                    │
                    ├── kranix-core (Deployment)
                    ├── kranix-api (Deployment + Service)
                    ├── kranix-operator (Deployment)
                    ├── kranix-mcp (Deployment + Service) [optional]
                    ├── CRDs (KranixApp, KranixNamespace, KranixPolicy)
                    └── RBAC (ClusterRole, ClusterRoleBinding, ServiceAccounts)
```

---

## Chart structure

```
kranix-charts/
├── charts/
│   ├── kranix/                  # Umbrella chart (installs everything)
│   │   ├── Chart.yaml
│   │   ├── values.yaml         # Default values
│   │   ├── templates/
│   │   │   ├── _helpers.tpl
│   │   │   ├── namespace.yaml
│   │   │   └── crds/           # CRD templates
│   │   └── charts/             # Sub-charts (vendored)
│   ├── kranix-core/             # Core engine chart
│   ├── kranix-api/              # API server chart
│   ├── kranix-operator/         # Operator chart
│   └── kranix-mcp/              # MCP server chart (optional)
├── ci/                         # CI values for chart testing
└── docs/                       # values.yaml reference docs
```

---

## Prerequisites

- Kubernetes 1.27+
- Helm 3.12+
- `kubectl` configured for your target cluster

---

## Install

### Add the Kranix Helm repository

```bash
helm repo add kranix https://charts.kranix.io
helm repo update
```

### Install with defaults

```bash
helm install kranix kranix/kranix \
  --namespace kranix-system \
  --create-namespace
```

### Install with custom values

```bash
helm install kranix kranix/kranix \
  --namespace kranix-system \
  --create-namespace \
  --values ./my-values.yaml
```

### Verify installation

```bash
kubectl get pods -n kranix-system
kubectl get crds | grep kranix.io
```

---

## Configuration (`values.yaml`)

### Global

```yaml
global:
  image:
    registry: ghcr.io/kranix-io
    pullPolicy: IfNotPresent
  serviceAccount:
    create: true
    name: kranix
```

### kranix-core

```yaml
core:
  enabled: true
  replicas: 1
  image:
    tag: "latest"
  config:
    reconcile_interval: 15s
    max_concurrent_reconciles: 10
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### kranix-api

```yaml
api:
  enabled: true
  replicas: 2
  image:
    tag: "latest"
  service:
    type: ClusterIP
    port: 8080
  ingress:
    enabled: false
    className: nginx
    host: kranix.example.com
    tls: true
  auth:
    mode: jwt                  # jwt | apikey | oidc
    jwtSecret: ""              # use secretRef in production
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
```

### kranix-operator

```yaml
operator:
  enabled: true
  replicas: 1
  image:
    tag: "latest"
  leaderElection: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi
```

### kranix-mcp (optional)

```yaml
mcp:
  enabled: false
  replicas: 1
  image:
    tag: "latest"
  service:
    type: ClusterIP
    port: 3100
  safety:
    readonlyMode: false
    allowDeleteWorkload: true
```

### State backend

```yaml
state:
  backend: postgres            # memory | postgres | etcd
  postgres:
    host: ""
    port: 5432
    database: kranix
    existingSecret: kranix-postgres-secret
    secretKey: postgres-password
```

### Metrics and observability

```yaml
metrics:
  enabled: true
  port: 9090
  serviceMonitor:
    enabled: false             # set true if using kube-prometheus-stack

tracing:
  enabled: false
  endpoint: ""                 # OTLP endpoint

logging:
  level: info
  format: json
```

---

## Multi-environment patterns

### Using Helm values overlays

```bash
# Base install
helm install kranix kranix/kranix -f values-base.yaml

# Environment-specific overlay
helm upgrade kranix kranix/kranix \
  -f values-base.yaml \
  -f values-production.yaml
```

### Example production overlay (`values-production.yaml`)

```yaml
api:
  replicas: 3
  ingress:
    enabled: true
    host: kranix.mycompany.com
    tls: true
  auth:
    mode: oidc

mcp:
  enabled: true

state:
  backend: postgres

metrics:
  serviceMonitor:
    enabled: true
```

---

## Upgrade

```bash
helm repo update
helm upgrade kranix kranix/kranix \
  --namespace kranix-system \
  --reuse-values
```

Check the [CHANGELOG.md](./CHANGELOG.md) before upgrading across major versions — some releases include CRD schema changes.

---

## Rollback

```bash
helm rollback kranix 1 --namespace kranix-system
```

---

## Uninstall

```bash
helm uninstall kranix --namespace kranix-system

# Remove CRDs (warning: deletes all KranixApp resources)
kubectl delete crds \
  kraneapps.kranix.io \
  kranenamespaces.kranix.io \
  kranepolicies.kranix.io
```

---

## Connectivity

| Repo | Relationship |
|---|---|
| `kranix-core` | Packaged as a sub-chart and deployed as a Deployment |
| `kranix-api` | Packaged as a sub-chart with a Service and optional Ingress |
| `kranix-operator` | Packaged as a sub-chart with CRDs and RBAC |
| `kranix-mcp` | Optional sub-chart, disabled by default |

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Use `helm lint` and `chart-testing` (ct) for all chart changes. CI runs `ct install` against a `kind` cluster on every PR.

```bash
ct lint --charts charts/kranix
ct install --charts charts/kranix
```

## License

Apache 2.0 — see [LICENSE](./LICENSE).
