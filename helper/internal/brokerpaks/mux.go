package brokerpaks

import (
	"log/slog"
	"net/http"

	awsses "github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/sns"

	"github.com/cloud-gov/csb/helper/internal/brokerpaks/ses"
)

func Handle(logger *slog.Logger, sesclient *awsses.Client, snsclient *sns.Client, topicarn string, snsdomain string) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("POST /brokerpaks/ses/reputation-alarm", ses.HandleSNSRequest(logger, sesclient, snsclient, topicarn, snsdomain))
	return mux
}
