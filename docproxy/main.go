package main

import (
	"embed"
	"log/slog"
	"net/http"
	"os"
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

// run registers routes and starts the server. It is separate from main so it
// can return errors conventionally and main can handle them all in one place.
func run() error {
	slog.SetLogLoggerLevel(slog.LevelInfo)
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
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		resp, err := http.Get("https://csb.dev.us-gov-west-1.aws-us-gov.cloud.gov")
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
	slog.Info("Starting server...")
	return http.ListenAndServe("localhost:8080", nil)
}

func main() {
	err := run()
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}
}
