# ArgoCD GitOps Deployment

This directory contains ArgoCD Application manifests for deploying the Kranix platform via GitOps.

## Prerequisites

- ArgoCD installed and configured
- Kubernetes cluster with ArgoCD access
- Helm repository added to ArgoCD

## Quick Start

### Add the Kranix Helm repository to ArgoCD

```bash
argocd repo add https://charts.kranix.io --type helm --name kranix
```

### Deploy the platform

Apply the Application manifest:

```bash
kubectl apply -f argocd/kranix-platform-app.yaml
```

### Customize values

Edit `argocd/values.yaml` to customize the deployment. The values are referenced in the Application manifest via `$values/argocd/values.yaml`.

## Application Structure

- `kranix-platform-app.yaml` - ArgoCD Application manifest for the full platform
- `values.yaml` - Default values for GitOps deployment
- `README.md` - This file

## Sync Policy

The Application is configured with:
- Automated sync with pruning and self-heal
- Namespace auto-creation
- Foreground propagation for safe deletions

## Manual Override

To manually sync the application:

```bash
argocd app sync kranix-platform
```

To view the application:

```bash
argocd app get kranix-platform
```
