{{/*
Resource sizing calculator for kranix-operator
Calculates recommended CPU and memory requests/limits based on workload count
*/}}

{{- define "kranix-operator.calculateResources" -}}
{{- $workloadCount := .Values.resourceCalculator.workloadCount | default 100 -}}
{{- $tier := .Values.resourceCalculator.tier | default "small" -}}

{{- $cpuRequest := "50m" -}}
{{- $cpuLimit := "100m" -}}
{{- $memoryRequest := "64Mi" -}}
{{- $memoryLimit := "128Mi" -}}

{{- if eq $tier "small" -}}
  {{- if lt $workloadCount 50 -}}
    {{- $cpuRequest = "50m" -}}
    {{- $cpuLimit = "100m" -}}
    {{- $memoryRequest = "64Mi" -}}
    {{- $memoryLimit = "128Mi" -}}
  {{- else if lt $workloadCount 200 -}}
    {{- $cpuRequest = "100m" -}}
    {{- $cpuLimit = "200m" -}}
    {{- $memoryRequest = "128Mi" -}}
    {{- $memoryLimit = "256Mi" -}}
  {{- else -}}
    {{- $cpuRequest = "200m" -}}
    {{- $cpuLimit = "500m" -}}
    {{- $memoryRequest = "256Mi" -}}
    {{- $memoryLimit = "512Mi" -}}
  {{- end -}}
{{- else if eq $tier "medium" -}}
  {{- if lt $workloadCount 100 -}}
    {{- $cpuRequest = "100m" -}}
    {{- $cpuLimit = "200m" -}}
    {{- $memoryRequest = "128Mi" -}}
    {{- $memoryLimit = "256Mi" -}}
  {{- else if lt $workloadCount 500 -}}
    {{- $cpuRequest = "200m" -}}
    {{- $cpuLimit = "500m" -}}
    {{- $memoryRequest = "256Mi" -}}
    {{- $memoryLimit = "512Mi" -}}
  {{- else -}}
    {{- $cpuRequest = "500m" -}}
    {{- $cpuLimit = "1000m" -}}
    {{- $memoryRequest = "512Mi" -}}
    {{- $memoryLimit = "1Gi" -}}
  {{- end -}}
{{- else if eq $tier "large" -}}
  {{- if lt $workloadCount 500 -}}
    {{- $cpuRequest = "500m" -}}
    {{- $cpuLimit = "1000m" -}}
    {{- $memoryRequest = "512Mi" -}}
    {{- $memoryLimit = "1Gi" -}}
  {{- else if lt $workloadCount 2000 -}}
    {{- $cpuRequest = "1000m" -}}
    {{- $cpuLimit = "2000m" -}}
    {{- $memoryRequest = "1Gi" -}}
    {{- $memoryLimit = "2Gi" -}}
  {{- else -}}
    {{- $cpuRequest = "2000m" -}}
    {{- $cpuLimit = "4000m" -}}
    {{- $memoryRequest = "2Gi" -}}
    {{- $memoryLimit = "4Gi" -}}
  {{- end -}}
{{- end -}}

{{- dict "cpuRequest" $cpuRequest "cpuLimit" $cpuLimit "memoryRequest" $memoryRequest "memoryLimit" $memoryLimit -}}
{{- end -}}
