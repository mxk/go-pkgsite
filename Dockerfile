# syntax=docker/dockerfile:1

FROM golang as build
ARG PKGSITE_VERSION=latest
WORKDIR /pkgsite
SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
ENV CGO_ENABLED=0 \
	GOBIN=/pkgsite \
	GOFLAGS="-trimpath '-ldflags=-s -w'"
RUN go install -tags=postgres \
	github.com/golang-migrate/migrate/v4/cmd/migrate@latest
RUN go install \
	golang.org/x/pkgsite/cmd/frontend@${PKGSITE_VERSION} \
	golang.org/x/pkgsite/cmd/worker@${PKGSITE_VERSION} \
	golang.org/x/pkgsite/devtools/cmd/db@${PKGSITE_VERSION} \
	golang.org/x/pkgsite/devtools/cmd/seeddb@${PKGSITE_VERSION}
RUN mod=$(go env GOMODCACHE) && \
	echo $mod/golang.org/x/pkgsite@* | cut -d@ -f2 > VERSION && \
	mv $mod/golang.org/x/pkgsite@*/{migrations,static,third_party} . && \
	rm */*.go
COPY . /proxy/
RUN cd /proxy/ && go build -o $GOBIN/proxy

# gcr.io/distroless/static is a better choice, but seeddb requires git
FROM alpine/git
ENV GO_DISCOVERY_LOG_LEVEL=warning \
	GO_DISCOVERY_DISABLE_ERROR_REPORTING=true
EXPOSE 80
WORKDIR /pkgsite
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /pkgsite .
ENTRYPOINT []
