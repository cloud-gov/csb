package main

import (
	_ "embed"
	"log/slog"
	"net/http"
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

func insertStylesheet(n *html.Node) {
	walk(n, func(n *html.Node) bool {
		if n.Type == html.ElementNode && n.Data == "head" {
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
			return false
		} else if n.Type == html.TextNode && n.Parent.Type == html.ElementNode && n.Parent.Data == "h1" {
			// Trim whitespace from header, which has a leading space
			n.Data = strings.Trim(n.Data, " ")
		}
		return false
	})
}

//go:embed styles.css
var stylesheet []byte

func run() error {
	http.HandleFunc("/styles.css", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Content-Type", "text/css; charset=utf-8")
		w.Write(stylesheet)
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

		insertStylesheet(doc)

		err = html.Render(w, doc)
		if err != nil {
			slog.Error("Rendering HTML", "error", err)
			w.WriteHeader(http.StatusInternalServerError)
		}
	})

	return http.ListenAndServe("localhost:8080", nil)
}

func main() {
	err := run()
	if err != nil {
		panic(err)
	}
}
