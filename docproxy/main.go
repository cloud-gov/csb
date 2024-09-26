package main

import (
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

func main() {
	resp, err := http.Get("https://csb.dev.us-gov-west-1.aws-us-gov.cloud.gov")
	if err != nil {
		panic(err)
	}

	doc, err := html.Parse(resp.Body)
	if err != nil {
		panic(err)
	}

	insertStylesheet(doc)

	file, err := os.Create("index.html")
	if err != nil {
		panic(err)
	}
	defer file.Close() // need to look up that thing about dealing with Close() errors.

	err = html.Render(file, doc)
	if err != nil {
		panic(err)
	}
}
