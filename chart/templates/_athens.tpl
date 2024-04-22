{{- define "go-pkgsite.ATHENS_GONOSUM_PATTERNS" -}}
{{- range $i, $priv := .Values.private }}
{{- if $i }},{{ end }}{{ $priv.host }}/*
{{- end }}
{{- end }}

{{- define "go-pkgsite.ATHENS_DOWNLOAD_MODE" -}}
downloadURL = {{ .Values.defaultProxy | quote }}
mode = "redirect"
{{- range .Values.private }}
download {{ .host | printf "%s/*" | quote }} { mode = "sync" }
{{- end }}
{{- end }}

{{- define "go-pkgsite.netrc" -}}
{{- range .Values.private -}}
machine {{ .host }} login {{ .username }}{{ with .password }} password {{ . }}{{ end }}
{{ end }}
{{- end }}

{{- define "go-pkgsite.gitconfig" -}}
{{- range .Values.private -}}
[url "https://{{ .username }}{{ with .password }}:{{ . }}{{ end }}@{{ .host }}"]
	insteadOf = "https://{{ .host }}"
{{ end }}
{{- end }}
