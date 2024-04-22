# Private pkg.go.dev server Helm chart

This [Helm] chart runs [golang/pkgsite][pkgsite] backed by [gomods/athens][athens] to provide a private documentation server that can access protected repositories.

[Helm]: https://helm.sh/
[pkgsite]: https://github.com/golang/pkgsite
[athens]: https://github.com/gomods/athens

## Local deployment on Rancher Desktop

1. Ensure that both Kubernetes and Traefik are enabled in [Rancher Desktop Preferences][prefs].
2. Run and follow instructions: `helm install go-pkgsite chart`

[prefs]: https://docs.rancherdesktop.io/ui/preferences/kubernetes/

## Private server credentials

Server-specific credentials can be supplied in a custom `values.yaml` file as follows:

```
private:
- host: gitlab.domain.com
  username: myusername
  password: mytoken
- host: github.domain.com
  username: mytoken
```

To deploy: `helm install go-pkgsite chart -f values.yaml`

As of 2024-04-22, [pkgsite] does not handle `.netrc` credentials, leading to [invalid links to source files][60299].

[60299]: https://github.com/golang/go/issues/60299
