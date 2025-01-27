package main

import (
	"embed"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strings"

	"github.com/cloud-gov/csb/helper/internal/config"
	"github.com/cloud-gov/csb/helper/internal/docproxy"
)

//go:embed assets
var assets embed.FS

func redirectHost(h http.Handler, c config.Config) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The CSB path /docs is routed to this app, but the Host header is still
		// the CSB's host. Redirect it.
		if strings.EqualFold(r.Host, c.BrokerURL.Host) {
			u := *r.URL
			u.Host = c.Host
			u.Scheme = "https"
			http.Redirect(w, r, u.String(), http.StatusMovedPermanently)
		} else {
			h.ServeHTTP(w, r)
		}
	})
}

func routes(c config.Config) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/", docproxy.HandleDocs(c))
	mux.Handle("/assets/", docproxy.HandleAssets(assets))

	return redirectHost(mux, c)
}

// run registers routes and starts the server. It is separate from main so it
// can return errors conventionally and main can handle them all in one place.
func run() error {
	slog.SetLogLoggerLevel(slog.LevelInfo)
	config, err := config.Load()
	if err != nil {
		return err
	}

	mux := routes(config)
	addr := fmt.Sprintf("%v:%v", config.ListenAddr, config.Port)
	slog.Info("Starting server...")
	return http.ListenAndServe(addr, mux)
}

func main() {
	err := run()
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}
}
