package main

import (
	"embed"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"

	"golang.org/x/net/html"
)

// walk traverses the nodes of the HTML document tree and calls f on each node. If f
// returns true, walk stops traversing.
func walk(n *html.Node, f func(*html.Node) bool) bool {
	if f(n) {
		return true
	}
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		if walk(c, f) {
			return true
		}
	}
	return false
}

// modifyDocument makes a series of changes to the html.Node in-place.
func modifyDocument(n *html.Node) {
	modifications := []func(*html.Node) bool{
		func(n *html.Node) bool {
			if n.Type == html.ElementNode && n.Data == "head" {
				// Inject our custom stylesheet.
				n.AppendChild(&html.Node{
					Type: html.ElementNode,
					Data: "link",
					Attr: []html.Attribute{
						{
							Key: "rel",
							Val: "stylesheet",
						},
						{
							Key: "href",
							Val: "assets/styles.css",
						},
					},
				})
				// Inject favicon.
				n.AppendChild(&html.Node{
					Type: html.ElementNode,
					Data: "link",
					Attr: []html.Attribute{
						{
							Key: "rel",
							Val: "icon",
						},
						{
							Key: "type",
							Val: "image/vnd.microsoft.icon",
						},
						{
							Key: "sizes",
							Val: "192x192",
						},
						{
							Key: "href",
							Val: "assets/images/favicon.ico",
						},
					},
				})
			}
			return false
		},
		func(n *html.Node) bool {
			if n.Type == html.TextNode && n.Parent.Type == html.ElementNode && n.Parent.Data == "h1" {
				// Trim whitespace from header, which has a leading space.
				n.Data = strings.Trim(n.Data, " ")
			}
			return false
		},
		func(n *html.Node) bool {
			if n.Type == html.TextNode && n.Parent.Type == html.ElementNode && n.Parent.Data == "title" {
				// Add title that is consistent with cloud.gov page titles.
				n.Data = "Services Reference | cloud.gov"
			}

			return false
		},
		func(n *html.Node) bool {
			if n.Type == html.TextNode && n.Parent.Parent.Type == html.ElementNode && n.Parent.Data == "a" {
				cls := html.Attribute{
					Key: "class",
					Val: "navbar-brand",
				}
				if i := slices.Index(n.Parent.Attr, cls); i >= 0 {
					// Change page title.
					n.Data = "Services Reference"
				}
			}
			return false
		},
		func(n *html.Node) bool {
			if n.Type == html.ElementNode && n.Data == "img" {
				// Replace the SES logo with a relative path. The brokerpak only compiles
				// with a full URL (not relative), so this must be done here.
				src := html.Attribute{
					Key: "src",
					Val: "https://services.cloud.gov/images/amazon-ses.svg",
				}
				newSrc := html.Attribute{
					Key: "src",
					Val: "assets/images/amazon-ses.svg",
				}
				if i := slices.Index(n.Attr, src); i >= 0 {
					n.Attr[i] = newSrc
				}
			}
			return false
		},
	}
	walk(n, func(n *html.Node) bool {
		for _, m := range modifications {
			stop := m(n)
			if stop {
				return true
			}
		}
		return false
	})
}

//go:embed assets
var assets embed.FS

func redirectHost(h http.Handler, c config) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The CSB path /docs is routed to this app, but the Host header is still
		// the CSB's host. Redirect it.
		if strings.EqualFold(r.Host, c.BrokerURL.Host) {
			// Get Path and RawQuery from original request
			u := *r.URL
			u.Host = c.Host
			u.Scheme = "https"
			http.Redirect(w, r, u.String(), http.StatusMovedPermanently)
		} else {
			h.ServeHTTP(w, r)
		}
	})
}

func httpError(w http.ResponseWriter, code int, message string) {
	w.WriteHeader(code)
	io.WriteString(w, message)
}

func serveAsset(w http.ResponseWriter, path string) {
	errBody := "An error in Cloud.gov occurred while serving this asset."

	asset, err := assets.ReadFile(path)
	if err != nil {
		httpError(w, http.StatusInternalServerError, errBody)
		slog.Error("failed to read asset from embedded fs", "path", path, "err", err)
		return
	}

	ext := filepath.Ext(path)
	var contentType string
	switch ext {
	case ".svg":
		contentType = "image/svg+xml"
	case ".ico":
		contentType = "image/vnd.microsoft.icon"
	case ".woff2":
		contentType = "font/woff2"
	case ".css":
		contentType = "text/css; charset=utf-8"
	default:
		slog.Error("tried serving asset with unknown file extension, and therefore no mapped content-type", "path", path)
		httpError(w, http.StatusInternalServerError, errBody)
		return
	}

	w.Header().Add("Content-Type", contentType)
	w.Write(asset)
}

func routes(c config) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/assets/", func(w http.ResponseWriter, r *http.Request) {
		fpath := strings.Join(strings.Split(r.URL.Path, "/")[1:], "/")
		serveAsset(w, fpath)
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		resp, err := http.Get(c.BrokerURL.String())
		if err != nil {
			slog.Error("Getting CSB site", "error", err)
			w.WriteHeader(http.StatusBadGateway)
		}

		doc, err := html.Parse(resp.Body)
		if err != nil {
			slog.Error("Parsing CSB response body", "error", err)
			w.WriteHeader(http.StatusInternalServerError)
		}

		modifyDocument(doc)

		err = html.Render(w, doc)
		if err != nil {
			slog.Error("Rendering HTML", "error", err)
			w.WriteHeader(http.StatusInternalServerError)
		}
	})
	return redirectHost(mux, c)
}

type config struct {
	// Host is the public URL for the application. Required for redirects to work.
	Host string
	// ListenAddr is the TCP address (without port) the process will bind to. For production, leave empty. For local development, use "localhost". Specify the port separately with [config.Port].
	ListenAddr string
	// Port is the TCP port the process will listen on. Specified separately because Cloud Foundry provides it to applications automatically.
	Port uint16
	// BrokerURL is the URL of the Cloud Service Broker instance that serves the documentation page.
	BrokerURL url.URL
}

func loadConfig() (config, error) {
	c := config{}

	c.Host = os.Getenv("HOST")
	c.ListenAddr = os.Getenv("LISTEN_ADDR")

	port := os.Getenv("PORT")
	p, err := strconv.ParseUint(port, 10, 16)
	if err != nil {
		return config{}, fmt.Errorf("Invalid PORT: %w", err)
	}
	c.Port = uint16(p)

	brokerURL := os.Getenv("BROKER_URL")
	u, err := url.Parse(brokerURL)
	if err != nil {
		return config{}, fmt.Errorf("Invalid BROKER_URL: %w", err)
	}
	// Add a scheme and parse again, or else the URL will be parsed as relative and fields we need later, like Host, will be empty. See [url.Parse] docs.
	if u.Scheme == "" {
		brokerURL = "https://" + brokerURL
	}
	u, err = url.Parse(brokerURL)
	if err != nil {
		return config{}, fmt.Errorf("Invalid BROKER_URL: %w", err)
	}

	c.BrokerURL = *u

	return c, nil
}

// run registers routes and starts the server. It is separate from main so it
// can return errors conventionally and main can handle them all in one place.
func run() error {
	slog.SetLogLoggerLevel(slog.LevelInfo)
	config, err := loadConfig()
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
