# syntax=docker/dockerfile:1

FROM golang as build
ARG PKGSITE_VERSION=latest
WORKDIR /pkgsite
SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
RUN CGO_ENABLED=0 GOBIN=$PWD go install -trimpath -ldflags='-s -w' \
	golang.org/x/pkgsite/cmd/frontend@${PKGSITE_VERSION}
RUN mod=$(go env GOMODCACHE) && \
    echo $mod/golang.org/x/pkgsite@* | cut -d@ -f2 > VERSION && \
	mv $mod/golang.org/x/pkgsite@*/{static,third_party} . && \
	rm */*.go

FROM gcr.io/distroless/static
ENV GO_DISCOVERY_LOG_LEVEL=warning \
	GO_DISCOVERY_DISABLE_ERROR_REPORTING=true
EXPOSE 80
WORKDIR /pkgsite
COPY --from=build /pkgsite .
ENTRYPOINT ["./frontend", "-direct_proxy", "-host=:80", "-local"]
