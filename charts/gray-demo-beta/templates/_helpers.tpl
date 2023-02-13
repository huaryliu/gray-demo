{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "gray-demo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gray-demo.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Kubernetes standard labels
*/}}
{{- define "common.labels.standard" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
helm.sh/chart: {{ include "common.names.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if and .Values.global.grayscale.enabled .Values.global.grayscale.subset }}
service.istio.io/canonical-revision: {{ .Values.global.grayscale.subset }}
{{- end }}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gray-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get image version
*/}}
{{- define "gray-demo.app.version" -}}
  {{- if .ContainerTag -}}
    {{- printf "%s" .ContainerTag }}
  {{- else if .AppVersion -}}
    {{- printf "%s" .AppVersion }}
  {{- else -}}
    {{- printf "latest" }}
  {{- end -}}
{{- end -}}

{{/*
Returns the default domain name
*/}}
{{- define "gray-demo.url.domain" }}
  {{- if .Values.global.grayscale.enabled }}
    {{- printf .Values.global.grayscale.host -}}
  {{- else if .Values.gateway.enabled -}}
    {{- printf (first .Values.gateway.hosts) -}}
  {{- else -}}
    {{- printf "id.inspures.com" -}}
  {{- end -}}
{{- end }}

{{/*
Returns the default public url scheme
*/}}
{{- define "gray-demo.url.scheme" }}
  {{- if .Values.gateway.tls }}
    {{- printf "https" -}}
  {{- else -}}
    {{- printf "http" -}}
  {{- end -}}
  
{{- end }}

{{- define "gray-demo.db.schema" -}}
  {{- if eq . "auth-api" -}}
    {{- printf "?currentSchema=pass_auth" }}
  {{- else if eq . "user-api" -}}
    {{- printf "?currentSchema=pass_user" }}
  {{- else if eq . "app-api" -}}
    {{- printf "?currentSchema=pass_app" }}
  {{- else -}}
    {{- printf "?currentSchema=public" }}
  {{- end -}}
{{- end -}}

{{/*
Returns the available value for certain key in an existing secret (if it exists),
otherwise it generates a random value.
*/}}
{{- define "getValueFromSecret" }}
{{- $len := (default 16 .Length) | int -}}
{{- $obj := (lookup "v1" "Secret" .Namespace .Name).data -}}
{{- if $obj }}
{{- index $obj .Key | b64dec -}}
{{- else -}}
{{- randAlphaNum $len -}}
{{- end -}}
{{- end }}

{{/*
Get volume mount path for specified container
*/}}
{{- define "getContainerMountPath" -}}
  {{- $serviceMountPath := get .allMountPaths .serviceName -}}
  {{- $containerMountPath := get $serviceMountPath "containerMountPath" -}}
  {{- if and (and $serviceMountPath $containerMountPath) (get $containerMountPath .containerName) -}}
    {{- printf (get $containerMountPath .containerName) }}
  {{- else if and $serviceMountPath (get $serviceMountPath "mountPath") -}}
    {{- printf (get $serviceMountPath "mountPath") }}
  {{- else -}}
    {{- printf "/data/share/%s/%s" .serviceName .containerName }}
  {{- end -}}
{{- end -}}


# {{/* Helm-Wrapper */}}
# {{- define "helm-wrapper.fullname" -}}
# {{- printf "%s-%s" .Release.Name "helm-wrapper" | trunc 63 | trimSuffix "-" -}}
# {{- end -}}

# {{- define "helm-wrapper.service.name" -}}
# {{- include "helm-wrapper.fullname" . }}
# {{- end -}}


{{/* PostgreSQL */}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "postgresql.service.name" -}}
{{- include "postgresql.fullname" . }}
{{- end -}}

{{/* MySQL */}}
{{- define "mysql.fullname" -}}
{{- printf "%s-%s" .Release.Name "mysql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mysql.service.name" -}}
{{- if not .Values.mysql.architecture }}
  {{- include "mysql.fullname" . }}
{{- else if eq .Values.mysql.architecture "replication" }}
  {{- printf "%s-primary" (include "mysql.fullname" .) }}
{{- else }}
  {{- include "mysql.fullname" . }}
{{- end -}}
{{- end -}}

{{/* Redis */}}
{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "redis.service.name" -}}
{{- printf "%s-master" (include "redis.fullname" .) }}
{{- end -}}

{{/* Cassandra */}}
{{- define "cassandra.fullname" -}}
{{- printf "%s-%s" .Release.Name "cassandra" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cassandra.service.name" -}}
{{- include "cassandra.fullname" . }}
{{- end -}}

{{/* Minio */}}
{{- define "minio.fullname" -}}
{{- printf "%s-%s" .Release.Name "minio" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "minio.service.name" -}}
{{- include "minio.fullname" . }}
{{- end -}}


{{/*
Render RDB connector envs.
*/}}
{{- define "renderRdbConnector" -}}
  {{- $c := . }}
  {{- if eq .type "SPRING_BOOT" }}
            - name: SPRING_DATASOURCE_URL
              value: jdbc:{{ .dbms }}://{{ .host }}:{{ .port }}/{{ .database }}?currentSchema={{ .schema }}
            - name: SPRING_DATASOURCE_USERNAME
              value: {{ .username }}
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .secretName }}
                  key: {{ .secretKey }}
  {{- else if eq .type "CUSTOM" }}
    {{- $global := .global }}
    {{- range $k, $v := .env }}
      {{- if eq $v "{{ .password }}" }}
            - name: {{ $k }}
              valueFrom:
                secretKeyRef:
                  name: {{ $c.secretName }}
                  key: {{ $c.secretKey }}
      {{- else }}
            - name: {{ $k }}
              value: {{ $v | replace "{{ .dbms }}" (print $c.dbms) | replace "{{ .host }}" (print $c.host) | replace "{{ .port }}" (print $c.port) | replace "{{ .database }}" (print $c.database) | replace "{{ .schema }}" (print $c.schema) | replace "{{ .username }}" (print $c.username) | quote }}
      {{- end }}
    {{- end }}
  {{- else }}
  {{- end }}
{{- end -}}

{{/*
Render Redis connector envs.
*/}}
{{- define "renderRedisConnector" -}}
  {{- $c := . }}
  {{- if eq .type "SPRING_BOOT" }}
            - name: SPRING_REDIS_HOST
              value: {{ .host }}
            - name: SPRING_REDIS_PORT
              value: {{ .port | quote }}
            - name: SPRING_REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .secretName }}
                  key: {{ .secretKey }}
  {{- else if eq .type "CUSTOM" }}
    {{- $global := .global }}
    {{- range $k, $v := .env }}
      {{- if eq $v "{{ .password }}" }}
            - name: {{ $k }}
              valueFrom:
                secretKeyRef:
                  name: {{ $c.secretName }}
                  key: {{ $c.secretKey }}
      {{- else }}
            - name: {{ $k }}
              value: {{ $v | replace "{{ .host }}" (print $c.host) | replace "{{ .port }}" (print $c.port) | replace "{{ .database }}" (print $c.database) | quote }}
      {{- end }}
    {{- end }}
  {{- else }}
  {{- end }}
{{- end -}}

{{/*
Render Cassandra connector envs.
*/}}
{{- define "renderCassandraConnector" -}}
  {{- $c := . }}
  {{- if eq .type "SPRING_BOOT" }}
            - name: SPRING_DATA_CASSANDRA_CONTACT_POINTS
              value: {{ .contactPoints }}
            - name: SPRING_DATA_CASSANDRA_PORT
              value: {{ .port | quote }}
            - name: SPRING_DATA_CASSANDRA_KEYSAPCE
              value: {{ .keyspace }}
            - name: SPRING_DATA_CASSANDRA_USERNAME
              value: {{ .port | quote }}
            - name: SPRING_DATA_CASSANDRA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .secretName }}
                  key: {{ .secretKey }}
  {{- else if eq .type "CUSTOM" }}
    {{- $global := .global }}
    {{- range $k, $v := .env }}
      {{- if eq $v "{{ .password }}" }}
            - name: {{ $k }}
              valueFrom:
                secretKeyRef:
                  name: {{ $c.secretName }}
                  key: {{ $c.secretKey }}
      {{- else }}
            - name: {{ $k }}
              value: {{ $v | replace "{{ .contactPoints }}" (print $c.contactPoints) | replace "{{ .port }}" (print $c.port) | replace "{{ .keyspace }}" (print $c.keyspace) | replace "{{ .username }}" (print $c.username) | quote }}
      {{- end }}
    {{- end }}
  {{- else }}
  {{- end }}
{{- end -}}

{{/*
Render S3 connector envs.
*/}}
{{- define "renderS3Connector" -}}
  {{- $c := . }}
  {{- if eq .type "SPRING_BOOT" }}
  {{- else if eq .type "CUSTOM" }}
    {{- $global := .global }}
    {{- range $k, $v := .env }}
      {{- if or (eq $v "{{ .secretKey }}") (eq $v "{{ .password }}") }}
            - name: {{ $k }}
              valueFrom:
                secretKeyRef:
                  name: {{ $c.secretName }}
                  key: {{ $c.secretKey }}
      {{- else }}
            - name: {{ $k }}
              value: {{ $v | replace "{{ .endpoint }}" (print $c.endpoint) | replace "{{ .port }}" (print $c.port) | replace "{{ .bucket }}" (print $c.bucket) | replace "{{ .accessKey }}" (print $c.accessKey) | quote }}
      {{- end }}
    {{- end }}
  {{- else }}
  {{- end }}
{{- end -}}
