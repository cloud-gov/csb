package docproxy

import (
	"embed"
	"log/slog"
	"net/http"
	"path/filepath"
	"slices"
	"strings"

	"golang.org/x/net/html"

	"github.com/cloud-gov/csb/helper/internal/config"
)

func serveAsset(w http.ResponseWriter, path string, assets embed.FS) {
	errBody := "An error in Cloud.gov occurred while serving this asset."

	asset, err := assets.ReadFile(path)
	if err != nil {
		http.Error(w, errBody, http.StatusInternalServerError)
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
		http.Error(w, errBody, http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-Type", contentType)
	w.Write(asset)
}

func HandleAssets(assets embed.FS) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			fpath := strings.Join(strings.Split(r.URL.Path, "/")[1:], "/")
			serveAsset(w, fpath, assets)
		},
	)
}

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

func HandleDocs(c config.Config) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			resp, err := http.Get(c.BrokerURL.String())
			if err != nil {
				slog.Error("Getting CSB site", "error", err)
				w.WriteHeader(http.StatusBadGateway)
			}
			defer resp.Body.Close() // todo can return error
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
		},
	)
}
