package main

import (
	"context"
	"embed"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"

	"github.com/aws/aws-sdk-go-v2/aws"
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

func routes(c config.Config, sesclient *ses.Client, snsdomain string) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/", docproxy.HandleDocs(c))
	mux.Handle("/assets/", docproxy.HandleAssets(assets))
	mux.Handle("/brokerpaks/", brokerpaks.Handle(sesclient, snsdomain))

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
		return fmt.Errorf("loading CSB Helper config: %w", err)
	}

	awscfg, err := awscfg.LoadDefaultConfig(ctx)
	if err != nil {
		return fmt.Errorf("loading AWS config: %w", err)
	}

	sesclient := ses.NewFromConfig(awscfg)

	snsendpoint, err := sns.NewDefaultEndpointResolverV2().ResolveEndpoint(ctx, sns.EndpointParameters{
		Region:  aws.String(awscfg.Region),
		UseFIPS: aws.Bool(true),
	})
	if err != nil {
		slog.Error("failed to resolve SES endpoint")
	}
	slog.Info("resolved SES endpoint", "endpoint", snsendpoint)

	mux := routes(config, sesclient, snsendpoint.URI.Host)
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
