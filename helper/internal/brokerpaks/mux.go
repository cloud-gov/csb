package brokerpaks

import (
	"net/http"

	awsses "github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/sns"

	"github.com/cloud-gov/csb/helper/internal/brokerpaks/ses"
)

func Handle(sesclient *awsses.Client, snsclient *sns.Client) http.Handler {
	mux := http.NewServeMux()
	mux.Handle("POST /ses/reputation-alarm", ses.HandleAlarm(sesclient, snsclient))
	return mux
}
