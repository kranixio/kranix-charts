# Contributing to kranix-charts

Thank you for your interest in contributing to kranix-charts!

## Development Setup

### Prerequisites

- Helm 3.12+
- Docker (for kind cluster)
- Python 3.9+ (for chart-testing)
- kubectl

### Install chart-testing

```bash
pip install chart-testing
```

### Install kind

```bash
go install sigs.k8s.io/kind@v0.20.0
```

## Workflow

### 1. Lint Charts

Before committing, always lint your changes:

```bash
ct lint --charts charts/kranix
```

This checks:
- Chart.yaml structure
- Values.yaml format
- Template syntax
- Best practices

### 2. Test Charts

Test charts against a kind cluster:

```bash
ct install --charts charts/kranix
```

This:
- Creates a kind cluster
- Installs the chart
- Validates the deployment

### 3. Update Dependencies

If you modify sub-charts, update dependencies:

```bash
helm dependency update charts/kranix
```

### 4. Render Templates

Verify template rendering:

```bash
helm template kranix charts/kranix --values charts/kranix/values.yaml
```

## Chart Changes

### Adding a New Sub-chart

1. Create the sub-chart in `charts/<name>/`
2. Add it to the umbrella chart's `Chart.yaml` dependencies
3. Update the umbrella chart's `values.yaml` with default configuration
4. Run `helm dependency update charts/kranix`
5. Update this CONTRIBUTING.md if needed

### Modifying Templates

- Use `{{- include "chart-name.selectorLabels" . | nindent 4 }}` for labels
- Follow the existing helper templates
- Use `toYaml` for complex values
- Add comments for non-obvious logic

### Adding New Values

1. Add the value to the sub-chart's `values.yaml`
2. Update the umbrella chart's `values.yaml` to expose it
3. Update the template to use the new value
4. Test with `helm template` and `ct install`

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `ct lint` and `ct install`
5. Submit a PR with:
   - Description of changes
   - Related issue number
   - Testing performed

## Code Style

- Use 2 spaces for indentation in YAML
- Follow Helm best practices
- Keep templates simple and readable
- Add comments for complex logic

## Release Process

1. Update chart versions in `Chart.yaml`
2. Update `CHANGELOG.md`
3. Tag the release
4. CI will automatically publish to the Helm repository
