{{- define "go-pkgsite.selectors" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "go-pkgsite.labels" -}}
{{ include "go-pkgsite.selectors" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "go-pkgsite.pgpasswd" -}}
valueFrom:
  secretKeyRef:
    name: {{ include "postgresql.v1.secretName" .Subcharts.postgresql }}
    key: {{ include "postgresql.v1.adminPasswordKey" .Subcharts.postgresql }}
{{- end }}

{{- define "go-pkgsite.pgenv" -}}
- name: PGHOST
  value: "{{ include "postgresql.v1.primary.fullname" .Subcharts.postgresql }}"
- name: PGPASSWORD
  {{- include "go-pkgsite.pgpasswd" . | nindent 2 }}
{{- end }}

{{- define "go-pkgsite.env" -}}
- name: GO_DISCOVERY_DATABASE_HOST
  value: {{ include "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
- name: GO_DISCOVERY_DATABASE_PASSWORD
  {{- include "go-pkgsite.pgpasswd" . | nindent 2 }}
- name: GO_DISCOVERY_LOG_LEVEL
  value: info
- name: GO_MODULE_PROXY_URL
  value: http://{{ .Release.Name }}-athens/
{{- end }}
