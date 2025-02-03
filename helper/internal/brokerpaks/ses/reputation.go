package ses

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/sns"
)

type SESClient interface {
	UpdateConfigurationSetSendingEnabled(context.Context, ses.UpdateConfigurationSetSendingEnabledInput) (ses.UpdateConfigurationSetSendingEnabledOutput, error)
}

type SNSRequest struct {
	Message      CloudWatchAlarm
	Subject      string
	SubscribeURL string
}

type CloudWatchAlarm struct {
	AlarmName     string
	NewStateValue string
	Trigger       struct {
		Dimensions []struct {
			Name  string
			Value string
		}
	}
}

// UnmarshalJSON is custom implemented here because the Message field contains a JSON object
// (the SNS message) encoded in a string, with escaped quotes. The default Unmarshaller cannot
// handle this.
func (s *SNSRequest) UnmarshalJSON(b []byte) error {
	// Unmarshal to an auxiliary type to get the string contents of all fields, including Message
	var aux struct {
		Message      string
		Subject      string
		SubscribeURL string
	}

	if err := json.Unmarshal(b, &aux); err != nil {
		return err
	}

	s.Subject = aux.Subject
	s.SubscribeURL = aux.SubscribeURL

	// Unmarshal the Message field separately
	return json.Unmarshal([]byte(aux.Message), &s.Message)
}

func (a *CloudWatchAlarm) Valid() map[string]string {
	verrs := make(map[string]string)
	prefix := "SES-BounceRate-Critical-Identity-"
	if !strings.HasPrefix(a.AlarmName, prefix) {
		verrs["AlarmName"] = fmt.Sprintf("expected alarm to have prefix %v, but name was %v", prefix, a.AlarmName)
	}
	if len(a.Trigger.Dimensions) == 0 {
		verrs["Trigger.Dimensions"] = fmt.Sprintf("expected one trigger dimension on the alarm, got 0")
		// return immediately to avoid index out of bounds panics
		return verrs
	}
	if l := len(a.Trigger.Dimensions); l > 1 {
		verrs["Trigger.Dimensions"] = fmt.Sprintf("expected only one trigger dimension on the alarm, got %v", l)
	}
	if name := a.Trigger.Dimensions[0].Name; name != "ConfigurationSetName" {
		verrs["Trigger.Dimensions[0].Name"] = fmt.Sprintf("expected alarm with name %v, got %v", "ConfigurationSetName", name)
	}
	return verrs
}

// parseRequests extracts the CloudWatch alarm from the body of the SNS request.
func ParseRequest(body io.Reader) (SNSRequest, error) {
	var s SNSRequest
	b, err := io.ReadAll(body)
	if err != nil {
		return s, fmt.Errorf("reading SNS request body: %w", err)
	}
	if len(b) == 0 {
		return s, fmt.Errorf("SNS request body was 0 bytes")
	}
	err = json.Unmarshal(b, &s)
	if err != nil {
		return s, fmt.Errorf("unmarshalling SNS request body: %w", err)
	}
	return s, nil
}

// TODO verify the SNS signature.
// TODO confirm subscription.
func HandleAlarm(sesclient *ses.Client, snsclient *sns.Client) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			// todo: check if request is subscription request.
			// check for SubscribeURL key?

			req, err := ParseRequest(r.Body)
			if err != nil {
				slog.Error("error processing CloudWatch alarm SNS request", "err", err)
				return
			}
			if errs := req.Message.Valid(); len(errs) > 0 {
				slog.Error("error validating CloudWatch alarm. is the SNS subscription FilterPolicy allowing non-SES notifications?", "errs", errs)
			}

			snsclient.ConfirmSubscription(context.Background(), &sns.ConfirmSubscriptionInput{})

			cset := req.Message.Trigger.Dimensions[0].Value

			_, err = sesclient.UpdateConfigurationSetSendingEnabled(r.Context(), &ses.UpdateConfigurationSetSendingEnabledInput{
				ConfigurationSetName: aws.String(cset),
				Enabled:              false,
			})
			if err != nil {
				slog.Error("error pausing sending on configuration set", "name", cset, "err", err)
			}
		},
	)
}
