package middleware_test

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/cloud-gov/csb/helper/internal/middleware"
)

func TestRedirectHost(t *testing.T) {
	oldHost := "old.example.com"
	newHost := "new.example.com"

	t.Run("redirects when host matches (case-insensitive)", func(t *testing.T) {
		testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// This shouldn't be called if redirect works
			t.Error("handler was called, but it should have redirected")
		})

		rr := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "http://"+oldHost+"/some/path", nil)
		req.Host = "OLD.Example.com" // test case-insensitive match

		handler := middleware.RedirectHost(testHandler, oldHost, newHost)
		handler.ServeHTTP(rr, req)

		if rr.Code != http.StatusMovedPermanently {
			t.Fatalf("expected status %d, got %d", http.StatusMovedPermanently, rr.Code)
		}
		loc := rr.Header().Get("Location")
		want := fmt.Sprintf("https://%s/some/path", newHost)
		if loc != want {
			t.Errorf("expected Location header %q, got %q", want, loc)
		}
	})

	t.Run("passes through when host doesn't match", func(t *testing.T) {
		testHandlerCalled := false
		testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			testHandlerCalled = true
			w.WriteHeader(http.StatusOK)
		})

		rr := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "http://some.otherhost.com/some/path", nil)
		req.Host = "some.otherhost.com"

		handler := middleware.RedirectHost(testHandler, oldHost, newHost)
		handler.ServeHTTP(rr, req)

		if rr.Code != http.StatusOK {
			t.Fatalf("expected status %d, got %d", http.StatusOK, rr.Code)
		}
		if !testHandlerCalled {
			t.Error("handler was not called when it should have been")
		}
	})
}
