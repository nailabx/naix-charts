{{/* ── Names ──────────────────────────────────────────────────────── */}}

{{- define "stateless.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "stateless.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "stateless.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* ── Labels ─────────────────────────────────────────────────────── */}}

{{- define "stateless.labels" -}}
helm.sh/chart: {{ include "stateless.chart" . }}
{{ include "stateless.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "stateless.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stateless.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* ── ServiceAccount name ────────────────────────────────────────── */}}

{{- define "stateless.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "stateless.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
── Resource names per feature ─────────────────────────────────────────
Each opt-in feature gets its own k8s resource named with a stable suffix
so multiple features can coexist without name collisions.
*/}}

{{- define "stateless.configMapName" -}}
{{- printf "%s-config" (include "stateless.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "stateless.externalSecretName" -}}
{{- printf "%s-secrets" (include "stateless.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "stateless.pluginConfigName" -}}
{{- printf "%s-plugins" (include "stateless.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
── envFrom for containers ─────────────────────────────────────────────
Builds the envFrom list that's auto-attached to each container.
Combines:
  - The synced ConfigMap (if configMap.enabled and configMap.mountAsEnv)
  - The synced ExternalSecret target (if externalSecret.enabled and mountAsEnv)
  - existingConfigMaps + existingSecrets (consumer-provided)
  - Per-container .extraEnvFrom

Usage in deployment template:
  {{- include "stateless.envFromBlock" (dict "ctx" $ "container" $container) | nindent 12 }}
*/}}

{{- define "stateless.envFromBlock" -}}
{{- $ctx := .ctx -}}
{{- $container := .container -}}
{{- $hasItems := false -}}
{{- if and $ctx.Values.configMap.enabled $ctx.Values.configMap.mountAsEnv -}}
{{- $hasItems = true -}}
{{- end -}}
{{- if and $ctx.Values.externalSecret.enabled $ctx.Values.externalSecret.mountAsEnv -}}
{{- $hasItems = true -}}
{{- end -}}
{{- if $ctx.Values.existingConfigMaps -}}{{- $hasItems = true -}}{{- end -}}
{{- if $ctx.Values.existingSecrets -}}{{- $hasItems = true -}}{{- end -}}
{{- if $container.extraEnvFrom -}}{{- $hasItems = true -}}{{- end -}}
{{- if $hasItems }}
envFrom:
{{- if and $ctx.Values.configMap.enabled $ctx.Values.configMap.mountAsEnv }}
  - configMapRef:
      name: {{ include "stateless.configMapName" $ctx }}
{{- end }}
{{- if and $ctx.Values.externalSecret.enabled $ctx.Values.externalSecret.mountAsEnv }}
  - secretRef:
      name: {{ include "stateless.externalSecretName" $ctx }}
{{- end }}
{{- range $ctx.Values.existingConfigMaps }}
  - configMapRef:
      name: {{ . }}
{{- end }}
{{- range $ctx.Values.existingSecrets }}
  - secretRef:
      name: {{ . }}
{{- end }}
{{- with $container.extraEnvFrom }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
{{- end }}

{{/*
── Sorted container keys ──────────────────────────────────────────────
Returns container map keys alphabetically sorted (the first is "primary").
Stable iteration order is critical — Helm's default map iteration is not
guaranteed in Go templates.
*/}}

{{- define "stateless.containerKeys" -}}
{{- $keys := list -}}
{{- range $name, $_ := .Values.containers -}}
{{- $keys = append $keys $name -}}
{{- end -}}
{{- sortAlpha $keys | toJson -}}
{{- end }}
