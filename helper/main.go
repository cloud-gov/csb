package main

import (
	"context"
	"embed"
	"fmt"
	"io"
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

func routes(c config.Config, logger *slog.Logger, sesclient *ses.Client, snsclient *sns.Client, snsdomain string) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/", docproxy.HandleDocs(logger, c))
	mux.Handle("/assets/", docproxy.HandleAssets(logger, assets))
	mux.Handle("/brokerpaks/", brokerpaks.Handle(logger, sesclient, snsclient, c.PlatformNotificationsTopicARN, snsdomain))

	// The CSB path /docs is routed to this app by Cloud Foundry, but the Host
	// header is still the CSB's host. Redirect it.
	return middleware.RedirectHost(mux, c.BrokerURL.Host, c.Host)
}

// run sets up dependencies, calls route registration, and starts the server.
// It is separate from main so it can return errors conventionally and main
// can handle them all in one place.
func run(ctx context.Context, out io.Writer) error {
	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()

	logger := slog.New(slog.NewTextHandler(out, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	config, err := config.Load()
	if err != nil {
		return fmt.Errorf("loading CSB Helper config: %w", err)
	}

	awscfg, err := awscfg.LoadDefaultConfig(ctx)
	if err != nil {
		return fmt.Errorf("loading AWS config: %w", err)
	}

	sesclient := ses.NewFromConfig(awscfg)
	snsclient := sns.NewFromConfig(awscfg)

	snsendpoint, err := sns.NewDefaultEndpointResolverV2().ResolveEndpoint(ctx, sns.EndpointParameters{
		Region:  aws.String(awscfg.Region),
		UseFIPS: aws.Bool(false), // This is used to validate the domain of the SigningCertURL, which will be non-FIPS
	})
	if err != nil {
		slog.Error("failed to resolve SNS endpoint")
	}
	slog.Info("resolved SNS endpoint", "endpoint", fmt.Sprintf("%+v", snsendpoint))

	mux := routes(config, logger, sesclient, snsclient, snsendpoint.URI.Host)
	addr := fmt.Sprintf("%v:%v", config.ListenAddr, config.Port)
	slog.Info("Starting server...")
	return http.ListenAndServe(addr, mux)
}

func main() {
	ctx := context.Background()
	err := run(ctx, os.Stdout)
	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	}
}
