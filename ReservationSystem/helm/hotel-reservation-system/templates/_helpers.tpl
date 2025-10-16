{{/*
Expand the name of the chart.
*/}}
{{- define "hotel-reservation.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hotel-reservation.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hotel-reservation.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hotel-reservation.labels" -}}
helm.sh/chart: {{ include "hotel-reservation.chart" . }}
{{ include "hotel-reservation.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: hotel-reservation-system
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hotel-reservation.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hotel-reservation.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hotel-reservation.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hotel-reservation.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate labels for a specific service
*/}}
{{- define "hotel-reservation.serviceLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
app.kubernetes.io/name: {{ $serviceName }}
app.kubernetes.io/instance: {{ $context.Release.Name }}
app.kubernetes.io/component: {{ $serviceName }}
app.kubernetes.io/part-of: hotel-reservation-system
app.kubernetes.io/managed-by: {{ $context.Release.Service }}
helm.sh/chart: {{ include "hotel-reservation.chart" $context }}
{{- if $context.Chart.AppVersion }}
app.kubernetes.io/version: {{ $context.Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Generate selector labels for a specific service
*/}}
{{- define "hotel-reservation.serviceSelectorLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
app.kubernetes.io/name: {{ $serviceName }}
app.kubernetes.io/instance: {{ $context.Release.Name }}
{{- end }}

{{/*
Generate image name with registry prefix if specified
*/}}
{{- define "hotel-reservation.image" -}}
{{- $registry := .registry -}}
{{- $repository := .repository -}}
{{- $tag := .tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Generate environment variables from a map
*/}}
{{- define "hotel-reservation.envVars" -}}
{{- range $key, $value := . }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Generate resource requirements
*/}}
{{- define "hotel-reservation.resources" -}}
{{- if . }}
resources:
  {{- if .requests }}
  requests:
    {{- if .requests.memory }}
    memory: {{ .requests.memory }}
    {{- end }}
    {{- if .requests.cpu }}
    cpu: {{ .requests.cpu }}
    {{- end }}
  {{- end }}
  {{- if .limits }}
  limits:
    {{- if .limits.memory }}
    memory: {{ .limits.memory }}
    {{- end }}
    {{- if .limits.cpu }}
    cpu: {{ .limits.cpu }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate security context
*/}}
{{- define "hotel-reservation.securityContext" -}}
{{- if . }}
securityContext:
  {{- if .runAsUser }}
  runAsUser: {{ .runAsUser }}
  {{- end }}
  {{- if .runAsGroup }}
  runAsGroup: {{ .runAsGroup }}
  {{- end }}
  {{- if .fsGroup }}
  fsGroup: {{ .fsGroup }}
  {{- end }}
  {{- if .runAsNonRoot }}
  runAsNonRoot: {{ .runAsNonRoot }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate database connection URL for PostgreSQL (JDBC format for Java services)
*/}}
{{- define "hotel-reservation.postgresUrl" -}}
{{- $host := .host -}}
{{- $port := .port -}}
{{- $database := .database -}}
{{- $user := .user -}}
{{- $password := .password -}}
jdbc:postgresql://{{ $host }}:{{ $port }}/{{ $database }}
{{- end }}

{{/*
Generate database connection URL for PostgreSQL (SQLAlchemy async format for Python services)
*/}}
{{- define "hotel-reservation.postgresPythonUrl" -}}
{{- $host := .host -}}
{{- $port := .port -}}
{{- $database := .database -}}
{{- $user := .user -}}
{{- $password := .password -}}
postgresql+asyncpg://{{ $user }}:{{ $password }}@{{ $host }}:{{ $port }}/{{ $database }}
{{- end }}

{{/*
Generate MongoDB connection URL
*/}}
{{- define "hotel-reservation.mongoUrl" -}}
{{- $host := .host -}}
{{- $port := .port -}}
{{- $database := .database -}}
{{- $user := .user -}}
{{- $password := .password -}}
mongodb://{{ $user }}:{{ $password }}@{{ $host }}:{{ $port }}/{{ $database }}
{{- end }}

{{/*
Generate Redis connection URL
*/}}
{{- define "hotel-reservation.redisUrl" -}}
{{- $host := .host -}}
{{- $port := .port -}}
redis://{{ $host }}:{{ $port }}
{{- end }}

{{/*
Generate Kafka bootstrap servers (using Bitnami Kafka chart service name)
*/}}
{{- define "hotel-reservation.kafkaBootstrapServers" -}}
hotel-reservation-kafka:9092
{{- end }}

{{/*
Generate RabbitMQ connection URL
*/}}
{{- define "hotel-reservation.rabbitmqUrl" -}}
{{- $host := .host -}}
{{- $port := .port -}}
{{- $user := .user -}}
{{- $password := .password -}}
amqp://{{ $user }}:{{ $password }}@{{ $host }}:{{ $port }}/
{{- end }}
