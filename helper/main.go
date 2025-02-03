package main

import (
	"context"
	"embed"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"

	awscfg "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/sns"

	"github.com/cloud-gov/csb/helper/internal/brokerpaks"
	"github.com/cloud-gov/csb/helper/internal/config"
	"github.com/cloud-gov/csb/helper/internal/docproxy"
	"github.com/cloud-gov/csb/helper/internal/middleware"
)

//go:embed assets
var assets embed.FS

func sesClient(ctx context.Context) (*ses.Client, error) {
	cfg, err := awscfg.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, err
	}
	return ses.NewFromConfig(cfg), nil
}

func snsClient(ctx context.Context) (*sns.Client, error) {
	cfg, err := awscfg.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, err
	}
	return sns.NewFromConfig(cfg), nil
}

func routes(c config.Config, sesclient *ses.Client, snsclient *sns.Client) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/", docproxy.HandleDocs(c))
	mux.Handle("/assets/", docproxy.HandleAssets(assets))

	mux.Handle("/brokerpaks/", brokerpaks.Handle(sesclient, snsclient))

	// The CSB path /docs is routed to this app by Cloud Foundry, but the Host
	// header is still the CSB's host. Redirect it.
	return middleware.RedirectHost(mux, c.BrokerURL.Host, c.Host)
}

// run sets up dependencies, calls route registration, and starts the server.
// It is separate from main so it can return errors conventionally and main
// can handle them all in one place.
func run(ctx context.Context) error {
	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()

	slog.SetLogLoggerLevel(slog.LevelInfo)
	config, err := config.Load()
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	sesclient, err := sesClient(ctx)
	if err != nil {
		return fmt.Errorf("creating AWS SES client: %w", err)
	}
	snsclient, err := snsClient(ctx)
	if err != nil {
		return fmt.Errorf("creating AWS SNS client: %w", err)
	}

	mux := routes(config, sesclient, snsclient)
	addr := fmt.Sprintf("%v:%v", config.ListenAddr, config.Port)
	slog.Info("Starting server...")
	return http.ListenAndServe(addr, mux)
}

func main() {
	ctx := context.Background()
	err := run(ctx)
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}
}
