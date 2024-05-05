// Tool for injecting netrc credentials into pkgsite/cmd/frontend requests.
//
// The frontend server makes "?go-get=1" requests to generate correct source
// code links. The relevant source is in pkgsite/internal/source/meta-tags.go.
// Unlike the go command, it does not have any support for using netrc files:
// https://github.com/golang/go/issues/60299
//
// Without private repo credentials, GitLab sends bogus responses to such
// requests: https://gitlab.com/gitlab-org/gitlab/-/issues/388573
//
// There is no easy fix without forking the frontend sever. Fortunately, when
// the https request fails, it falls back to http. This allows us to use
// HTTP[S]_PROXY to intercept these requests and inject the credentials.
package main

import (
	"flag"
	"log"
	"net/http"
	"os/user"
	"path/filepath"
	"runtime"
	"time"

	"github.com/jdx/go-netrc"
	"gopkg.in/elazarl/goproxy.v1"
)

var (
	host      = flag.String("host", "localhost:8080", "Host address for the server")
	netrcFile = flag.String("netrc", "", "Netrc file path")
	verbose   = flag.Bool("verbose", false, "Verbose output")
)

func main() {
	flag.Parse()
	rc, err := loadNetrc(*netrcFile)
	if err != nil {
		log.Fatal(err)
	}

	p := goproxy.NewProxyHttpServer()
	p.NonproxyHandler = http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		http.Error(w, "Proxy Server OK", http.StatusOK)
	})

	rcMatch := p.OnRequest(rc)
	rcMatch.HandleConnectFunc(func(host string, _ *goproxy.ProxyCtx) (*goproxy.ConnectAction, string) {
		if *verbose {
			log.Println("Rejecting CONNECT:", host)
		}
		return goproxy.RejectConnect, host
	})
	rcMatch.DoFunc(func(req *http.Request, ctx *goproxy.ProxyCtx) (*http.Request, *http.Response) {
		req.URL.Scheme = "https"
		if req.URL.RawQuery == "go-get=1" && req.Header.Get("Authorization") == "" {
			auth := rc[req.URL.Hostname()]
			req.SetBasicAuth(auth.login, auth.password)
			if *verbose {
				log.Println("Authorizing:", req.Method, req.URL.String())
			}
		} else if *verbose {
			log.Println("Ignoring:", req.Method, req.URL.String())
		}
		return req, nil
	})

	log.Println("Listening on", *host)
	s := &http.Server{Addr: *host, Handler: p, ReadHeaderTimeout: 5 * time.Second}
	log.Fatal(s.ListenAndServe())
}

type (
	machines  map[string]basicAuth
	basicAuth struct{ login, password string }
)

func loadNetrc(path string) (machines, error) {
	if path == "" {
		usr, err := user.Current()
		if err != nil {
			return nil, err
		}
		file := ".netrc"
		if runtime.GOOS == "windows" {
			file = "_netrc"
		}
		path = filepath.Join(usr.HomeDir, file)
	}
	rc, err := netrc.Parse(path)
	if err != nil {
		return nil, err
	}
	all := make(machines, len(rc.Machines()))
	for _, m := range rc.Machines() {
		auth := basicAuth{m.Get("login"), m.Get("password")}
		if !m.IsDefault && auth.login != "" {
			all[m.Name] = auth
		}
	}
	return all, nil
}

func (m machines) HandleReq(req *http.Request, _ *goproxy.ProxyCtx) bool {
	_, ok := m[req.URL.Hostname()]
	return ok
}

func (machines) HandleResp(*http.Response, *goproxy.ProxyCtx) bool {
	return false
}
