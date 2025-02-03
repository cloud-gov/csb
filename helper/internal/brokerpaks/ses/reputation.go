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
)

type SESClient interface {
	UpdateConfigurationSetSendingEnabled(context.Context, ses.UpdateConfigurationSetSendingEnabledInput) (ses.UpdateConfigurationSetSendingEnabledOutput, error)
}

type SNSRequest struct {
	Message string
	Subject string
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
func ParseRequest(body io.Reader) (CloudWatchAlarm, error) {
	var a CloudWatchAlarm
	b, err := io.ReadAll(body)
	if err != nil {
		return a, fmt.Errorf("reading SNS request body: %w", err)
	}
	if len(b) == 0 {
		return a, fmt.Errorf("SNS request body was 0 bytes")
	}
	var s SNSRequest
	err = json.Unmarshal(b, &s)
	if err != nil {
		return a, fmt.Errorf("unmarshalling SNS request body: %w", err)
	}

	err = json.Unmarshal([]byte(s.Message), &a)
	if err != nil {
		return a, fmt.Errorf("unmarshalling CloudWatch alarm from SNS request message field: %w", err)
	}

	return a, nil
}

// TODO verify the SNS signature.
// TODO confirm subscription.
func HandleAlarm(sesclient *ses.Client) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			alarm, err := ParseRequest(r.Body)
			if err != nil {
				slog.Error("error processing CloudWatch alarm SNS request", "err", err)
				return
			}
			if errs := alarm.Valid(); len(errs) > 0 {
				slog.Error("error validating CloudWatch alarm. is the SNS subscription FilterPolicy allowing non-SES notifications?", "errs", errs)
			}

			cset := alarm.Trigger.Dimensions[0].Value

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
