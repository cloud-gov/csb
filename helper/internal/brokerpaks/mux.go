package brokerpaks

import (
	"net/http"

	awsses "github.com/aws/aws-sdk-go-v2/service/ses"

	"github.com/cloud-gov/csb/helper/internal/brokerpaks/ses"
)

func Handle(sesclient *awsses.Client, snsdomain string) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("POST /brokerpaks/ses/reputation-alarm", ses.HandleSNSRequest(sesclient, snsdomain))
	return mux
}
