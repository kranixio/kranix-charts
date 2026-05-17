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
- Production-ready profile with HA replicas, PodDisruptionBudgets, and anti-affinity rules
- OpenTelemetry integration for distributed tracing and metrics
- Pre-upgrade validation hooks to prevent failed upgrades
- Standalone chart installation for individual components
- ArgoCD app-of-apps template for GitOps deployment
- Resource sizing calculator for automatic resource recommendations

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

### Install full platform (umbrella chart)

```bash
helm install kranix kranix/kranix \
  --namespace kranix-system \
  --create-namespace
```

### Install individual components (standalone charts)

Each component can be installed independently:

```bash
# Install only kranix-core
helm install kranix-core kranix/kranix-core \
  --namespace kranix-system \
  --create-namespace

# Install only kranix-operator
helm install kranix-operator kranix/kranix-operator \
  --namespace kranix-system \
  --create-namespace

# Install only kranix-mcp
helm install kranix-mcp kranix/kranix-mcp \
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

### Production-ready profile

Enable high-availability configurations with a single flag:

```yaml
kranix-core:
  productionReady:
    enabled: true
    replicas: 3
    podDisruptionBudget:
      enabled: true
      minAvailable: 2
    antiAffinity:
      enabled: true
      type: hard                # hard or soft
```

When enabled, this profile:
- Sets high replica counts for HA
- Creates PodDisruptionBudgets to ensure minimum availability during disruptions
- Configures pod anti-affinity rules to spread pods across nodes
- Can be configured per-component (kranix-core, kranix-api, kranix-operator)

### OpenTelemetry integration

Enable distributed tracing and metrics collection:

```yaml
kranix-core:
  opentelemetry:
    enabled: true
    endpoint: "http://opentelemetry-collector.observability.svc.cluster.local:4317"
    tracing:
      enabled: true
      samplingRatio: 1.0
    metrics:
      enabled: true
      port: 9464
      path: /metrics
    resourceAttributes:
      service.name: kranix-core
      deployment.environment: production
```

Features:
- Exports traces to OpenTelemetry Collector via OTLP
- Exposes Prometheus metrics endpoint for scraping
- Configurable sampling ratio for traces
- Service-level resource attributes for filtering

### Pre-upgrade validation hooks

Run validation checks before Helm upgrades to prevent failures:

```yaml
kranix-core:
  preUpgradeHook:
    enabled: true
    image:
      repository: bitnami/kubectl
      tag: "latest"
    checks:
      resources:
        enabled: true
        minCpu: "100m"
        minMemory: "128Mi"
      dependencies:
        enabled: true
        services:
          - postgres
      secrets:
        enabled: true
        required:
          - kranix-postgres-secret
```

Validation checks include:
- Resource availability (CPU, memory)
- Dependent service readiness
- Required secret existence
- Hook runs as a Kubernetes Job with `pre-upgrade` annotation

### Resource sizing calculator

Automatically calculate recommended CPU and memory resources based on workload count and deployment tier:

```yaml
kranix-core:
  resourceCalculator:
    enabled: true
    workloadCount: 500           # Expected number of workloads
    tier: medium                 # small, medium, or large
```

The calculator provides tier-based resource recommendations:

**Small tier (up to 200 workloads):**
- kranix-core: 100m-500m CPU, 128Mi-512Mi memory
- kranix-api: 100m-500m CPU, 128Mi-512Mi memory
- kranix-operator: 50m-200m CPU, 64Mi-256Mi memory

**Medium tier (up to 500 workloads):**
- kranix-core: 200m-1000m CPU, 256Mi-1Gi memory
- kranix-api: 200m-1000m CPU, 256Mi-1Gi memory
- kranix-operator: 100m-500m CPU, 128Mi-512Mi memory

**Large tier (2000+ workloads):**
- kranix-core: 1000m-4000m CPU, 512Mi-4Gi memory
- kranix-api: 1000m-4000m CPU, 512Mi-4Gi memory
- kranix-operator: 500m-2000m CPU, 256Mi-2Gi memory

When enabled, the calculator overrides manual resource settings with calculated values.

### ArgoCD GitOps deployment

The charts include an ArgoCD Application manifest for GitOps-based deployment:

```bash
# Add Helm repository to ArgoCD
argocd repo add https://charts.kranix.io --type helm --name kranix

# Deploy via ArgoCD
kubectl apply -f argocd/kranix-platform-app.yaml
```

See `argocd/README.md` for detailed GitOps deployment instructions.

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
  # Enable production-ready profile
  productionReady:
    enabled: true
    replicas: 3
  # Enable OpenTelemetry
  opentelemetry:
    enabled: true
  # Enable pre-upgrade validation
  preUpgradeHook:
    enabled: true
  # Enable resource calculator
  resourceCalculator:
    enabled: true
    workloadCount: 500
    tier: medium

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
