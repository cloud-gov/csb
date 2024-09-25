package main

import (
	"bytes"
	"encoding/xml"
	"os"
	"strings"
	// "strings"
)

var data = []byte(`
<html>
	<head>
		<title>Hi there blah</title>
	</head>
	<body>
		<h1>This is dog</h1>
		<p>tommy</p>
		<pre>This is
Some content</pre>
	</body>
</html>
`)

// Node represents a generic element in an XML document tree.
type Node struct {
	XMLName xml.Name
	Attrs   []xml.Attr `xml:",attr"`
	Content string     `xml:",chardata"`
	Nodes   []*Node    `xml:",any"`
}

func (n *Node) UnmarshalXML(d *xml.Decoder, start xml.StartElement) error {
	n.Attrs = start.Attr
	// Avoid recursively calling UnmarshalXML by casting to an alias type.
	type node Node
	err := d.DecodeElement((*node)(n), &start)
	if err != nil {
		return err
	}

	// Avoid printing xml-encoded newline and tab characters, which may be part of the
	// content of container elements like html and div. But, leave them intact for
	// elements that have other contents. This is important for HTML elements where
	// formatting characters are meaningful, like <pre>.
	content := strings.ReplaceAll(n.Content, "\n", "")
	content = strings.ReplaceAll(content, "\t", "")
	if len(content) == 0 {
		n.Content = content
	}

	return nil
}

// walk traverses the nodes of an XML document tree and performs some action, specified
// by function f, on each node. It stops traversing if f returns false.

// Based on: https://stackoverflow.com/a/30257684
func walk(nodes []*Node, f func(*Node) bool) {
	for _, n := range nodes {
		if f(n) {
			walk(n.Nodes, f)
		}
	}
}

func main() {
	buf := bytes.NewBuffer(data)
	dec := xml.NewDecoder(buf)

	var n = new(Node)
	err := dec.Decode(n)
	if err != nil {
		panic(err)
	}

	walk([]*Node{n}, func(n *Node) bool {
		if n.XMLName.Local == "body" {
			n.Nodes = append(n.Nodes, &Node{
				XMLName: xml.Name{
					Local: "a",
				},
				Attrs: []xml.Attr{
					xml.Attr{
						Name: xml.Name{
							Local: "href",
						},
						Value: "https://google.com",
					},
				},
				Content: "Google",
			})
		}
		return true
	})

	file, err := os.Create("index.html")
	if err != nil {
		panic(err)
	}
	defer file.Close() // need to look up that thing about dealing with Close() errors.
	enc := xml.NewEncoder(file)
	enc.Indent("", "\t")
	err = enc.Encode(n)
	if err != nil {
		panic(err)
	}
}

// find the content element
// add an a href after

// find the head element
// add a new meta element to the end of
