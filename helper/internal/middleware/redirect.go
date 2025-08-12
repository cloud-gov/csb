package middleware

import (
	"net/http"
	"strings"
)

// RedirectHost checks if the request Host header matches `old` and redirects
// to host `new` if so. Otherwise, the request is handled normally.
func RedirectHost(h http.Handler, old string, new string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.EqualFold(r.Host, old) {
			u := *r.URL
			u.Host = new
			u.Scheme = "https"
			http.Redirect(w, r, u.String(), http.StatusMovedPermanently)
		} else {
			h.ServeHTTP(w, r)
		}
	})
}
