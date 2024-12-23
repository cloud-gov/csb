package main

import (
	"embed"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"os"
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
ModifyDocument:
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
							Val: "styles.css",
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
							Val: "/images/favicon.ico",
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
				src := html.Attribute{
					Key: "src",
					Val: "https://example.com/icon.jpg",
				}
				newSrc := html.Attribute{
					Key: "src",
					Val: "images/amazon-ses.svg",
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

//go:embed styles.css
var stylesheet []byte

//go:embed fonts
var fonts embed.FS

//go:embed images/favicon.ico
var favicon []byte

//go:embed images/cloud-gov-logo.svg
var logo []byte

//go:embed images/amazon-ses.svg
var amazonSES []byte

func routes(c config) {
	http.HandleFunc("/styles.css", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Content-Type", "text/css; charset=utf-8")
		w.Write(stylesheet)
	})
	http.HandleFunc("/fonts/", func(w http.ResponseWriter, r *http.Request) {
		b, err := fonts.ReadFile(strings.TrimPrefix(r.URL.Path, "/"))
		if err != nil {
			slog.Error("Reading font file", "error", err)
			w.WriteHeader(http.StatusInternalServerError)
		}
		w.Header().Add("Content-Type", "font/woff2")
		w.Write(b)
	})
	http.HandleFunc("/images/favicon.ico", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Content-Type", "image/vnd.microsoft.icon")
		w.Write(favicon)
	})
	http.HandleFunc("/images/cloud-gov-logo.svg", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Content-Type", "image/svg+xml")
		w.Write(logo)
	})
	http.HandleFunc("/images/amazon-ses.svg", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Content-Type", "image/svg+xml")
		w.Write(amazonSES)
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
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
}

type config struct {
	Host      string
	Port      uint16
	BrokerURL *url.URL
}

func loadConfig() (config, error) {
	c := config{}

	// Host can be empty, for local development, a value like "localhost".
	c.Host = os.Getenv("HOST")

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
	c.BrokerURL = u

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

	routes(config)
	addr := fmt.Sprintf("%v:%v", config.Host, config.Port)
	slog.Info("Starting server...")
	return http.ListenAndServe(addr, nil)
}

func main() {
	err := run()
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}
}
