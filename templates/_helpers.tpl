{{/*
Expand the name of the chart.
*/}}
{{- define "registry-mirror.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "registry-mirror.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "registry-mirror.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for a mirror instance.
Takes a dict with keys: root (top-level context) and mirror (the mirror entry).
*/}}
{{- define "registry-mirror.labels" -}}
helm.sh/chart: {{ include "registry-mirror.chart" .root }}
{{ include "registry-mirror.selectorLabels" . }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}

{{/*
Selector labels for a mirror instance.
*/}}
{{- define "registry-mirror.selectorLabels" -}}
app.kubernetes.io/name: {{ include "registry-mirror.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .mirror.name }}
{{- end }}

{{/*
Resource name for a mirror instance.
*/}}
{{- define "registry-mirror.resourceName" -}}
{{- printf "%s-%s" (include "registry-mirror.fullname" .root) .mirror.name | trunc 63 | trimSuffix "-" }}
{{- end }}
