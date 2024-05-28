# Private pkg.go.dev server Helm chart

This [Helm] chart runs [golang/pkgsite][pkgsite] backed by [gomods/athens][athens] to provide a private documentation server that can access protected repositories.

[helm]: https://helm.sh/
[pkgsite]: https://github.com/golang/pkgsite
[athens]: https://github.com/gomods/athens

## Setup

### Deployment

```
helm upgrade -i go-pkgsite oci://registry-1.docker.io/mxkh/go-pkgsite
```

See [chart/values.yaml][values] for customization options.

If deploying on Rancher Desktop, ensure that both Kubernetes and Traefik are enabled in [preferences].

[values]: https://github.com/mxk/go-pkgsite/blob/main/chart/values.yaml
[preferences]: https://docs.rancherdesktop.io/ui/preferences/kubernetes/

### Private server credentials

Server-specific credentials can be supplied in a custom `values.yaml` file as follows:

```
private:
- host: gitlab.example.com
  username: myusername
  password: mytoken
- host: github.example.com
  username: mytoken
```

To deploy: `helm upgrade -i go-pkgsite oci://registry-1.docker.io/mxkh/go-pkgsite -f values.yaml`

To avoid storing passwords in `values.yaml`, provide them on the command line using `--set-string private[0].password=...`.

### Ingress TLS

Ingress TLS key and certificate can be configured via: `helm upgrade -i go-pkgsite oci://registry-1.docker.io/mxkh/go-pkgsite -f values.yaml --set-file tlsKey=key.pem,tlsCrt=crt.pem`

## Known Issues

### .netrc support

As of May 2024, [pkgsite] does not handle `.netrc` credentials, leading to [invalid links to source files][60299]. To work around this (without forking pkgsite), the chart runs a custom proxy server that intercepts all `?go-get=1` requests from `frontend` and injects the appropriate credentials. This has been tested with a private GitLab instance, but may cause problems for other installations.

[60299]: https://github.com/golang/go/issues/60299

## Release publication

TODO: Automate

1. Update dependencies: `helm dependency update chart`
2. Bump version in `chart/Chart.yaml`.
3. Create and tag release commit.
4. Rebuild Docker image: `docker build --no-cache -t mxkh/go-pkgsite -t mxkh/go-pkgsite:<version>-alpine .`
   * Version tag must have a suffix to differentiate it from the OCI Helm package.
5. Push Docker image: `docker push mxkh/go-pkgsite mxkh/go-pkgsite:<version>-alpine`
6. Package and push chart: `helm package chart && helm push go-pkgsite-*.tgz oci://registry-1.docker.io/mxkh`
