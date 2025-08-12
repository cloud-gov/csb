package ses_test

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	awsses "github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/sns"

	"github.com/cloud-gov/csb/helper/internal/brokerpaks/ses"
)

var referenceAlarm = `{
    "Type": "Notification",
    "MessageId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "TopicArn": "arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms",
    "Subject": "ALARM: \"Example alarm name\" in EU - Ireland",
    "Message": "{\"AlarmName\":\"Example alarm name\",\"AlarmDescription\":\"Example alarm description.\",\"AWSAccountId\":\"000000000000\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold Crossed: 1 datapoint (10.0) was greater than or equal to the threshold (1.0).\",\"StateChangeTime\":\"2017-01-12T16:30:42.236+0000\",\"Region\":\"EU - Ireland\",\"OldStateValue\":\"OK\",\"Trigger\":{\"MetricName\":\"DeliveryErrors\",\"Namespace\":\"ExampleNamespace\",\"Statistic\":\"SUM\",\"Unit\":null,\"Dimensions\":[{\"Name\":\"ConfigurationSetName\",\"Value\":\"ExampleConfigurationSet\"}],\"Period\":300,\"EvaluationPeriods\":1,\"ComparisonOperator\":\"GreaterThanOrEqualToThreshold\",\"Threshold\":1.0}}",
    "Timestamp": "2017-01-12T16:30:42.318Z",
    "SignatureVersion": "1",
    "Signature": "Cg==",
    "SigningCertUrl": "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.pem",
    "UnsubscribeUrl": "https://sns.eu-west-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "MessageAttributes": {}
  }`

func TestParseRequest(t *testing.T) {
	r := strings.NewReader(referenceAlarm)
	msg, err := ses.UnmarshalMessage(r)
	if err != nil {
		t.Fatal("error while parsing request: ", err)
	}
	var alarm ses.CloudWatchAlarm
	if err = json.Unmarshal([]byte(msg.Message), &alarm); err != nil {
		t.Fatalf("unmarshalling alarm: %v", err.Error())
	}

	expectedName := "Example alarm name"
	if alarm.AlarmName != expectedName {
		t.Fatalf("expected alarm name %v, got %v", expectedName, alarm.AlarmName)
	}
	expectedNewStateValue := "ALARM"
	if alarm.NewStateValue != expectedNewStateValue {
		t.Fatalf("expected NewStateValue %v, got %v", expectedNewStateValue, alarm.NewStateValue)
	}
	if l := len(alarm.Trigger.Dimensions); l != 1 {
		t.Fatalf("expected len(Dimensions) == 1, got %v", l)
	}
	d := alarm.Trigger.Dimensions[0]
	expectedDimName := "ConfigurationSetName"
	if d.Name != expectedDimName {
		t.Fatalf("expected name %v, got %v", expectedDimName, d.Name)
	}
	expectedDimValue := "ExampleConfigurationSet"
	if d.Value != expectedDimValue {
		t.Fatalf("expected value %v, got %v", expectedDimValue, d.Value)
	}
}

func TestAlarmValid(t *testing.T) {
	cases := []struct {
		Name  string
		Alarm ses.CloudWatchAlarm
		VErrs map[string]string
	}{
		{
			Name: "valid alarm has no errors",
			Alarm: ses.CloudWatchAlarm{
				AlarmName:     "SES-BounceRate-Critical-Identity-ExampleSet",
				NewStateValue: "OK",
				Trigger: struct {
					Dimensions []struct {
						Name  string
						Value string
					}
				}{
					Dimensions: []struct {
						Name  string
						Value string
					}{
						{Name: "ConfigurationSetName", Value: "ExampleValue"},
					},
				},
			},
			VErrs: map[string]string{},
		},
		{
			Name: "alarm name missing prefix",
			Alarm: ses.CloudWatchAlarm{
				AlarmName: "WrongPrefix-Identity-ExampleSet",
				Trigger: struct {
					Dimensions []struct {
						Name  string
						Value string
					}
				}{
					Dimensions: []struct {
						Name  string
						Value string
					}{
						{Name: "ConfigurationSetName", Value: "Val"},
					},
				},
			},
			VErrs: map[string]string{
				"AlarmName": "expected alarm to have prefix SES-BounceRate-Critical-Identity-, but name was WrongPrefix-Identity-ExampleSet",
			},
		},
		{
			Name: "trigger has no dimensions",
			Alarm: ses.CloudWatchAlarm{
				AlarmName: "SES-BounceRate-Critical-Identity-ExampleSet",
				Trigger: struct {
					Dimensions []struct {
						Name  string
						Value string
					}
				}{
					Dimensions: []struct {
						Name  string
						Value string
					}{},
				},
			},
			VErrs: map[string]string{
				"Trigger.Dimensions": "expected one trigger dimension on the alarm, got 0",
			},
		},
		{
			Name: "trigger has multiple dimensions",
			Alarm: ses.CloudWatchAlarm{
				AlarmName: "SES-BounceRate-Critical-Identity-ExampleSet",
				Trigger: struct {
					Dimensions []struct {
						Name  string
						Value string
					}
				}{
					Dimensions: []struct {
						Name  string
						Value string
					}{
						{Name: "ConfigurationSetName", Value: "Val1"},
						{Name: "ConfigurationSetName", Value: "Val2"},
					},
				},
			},
			VErrs: map[string]string{
				"Trigger.Dimensions": "expected only one trigger dimension on the alarm, got 2",
			},
		},
		{
			Name: "dimension has incorrect name",
			Alarm: ses.CloudWatchAlarm{
				AlarmName: "SES-BounceRate-Critical-Identity-ExampleSet",
				Trigger: struct {
					Dimensions []struct {
						Name  string
						Value string
					}
				}{
					Dimensions: []struct {
						Name  string
						Value string
					}{
						{Name: "WrongName", Value: "Val"},
					},
				},
			},
			VErrs: map[string]string{
				"Trigger.Dimensions[0].Name": "expected alarm with name ConfigurationSetName, got WrongName",
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.Name, func(t *testing.T) {
			got := tc.Alarm.Valid()

			// Quick check: same number of errors
			if len(got) != len(tc.VErrs) {
				t.Fatalf("expected %d errors, got %d: %v", len(tc.VErrs), len(got), got)
			}

			// Compare each key/value
			for k, wantMsg := range tc.VErrs {
				gotMsg, ok := got[k]
				if !ok {
					t.Errorf("expected an error for key %q, but none found", k)
					continue
				}
				if gotMsg != wantMsg {
					t.Errorf("for key %q:\nexpected: %q\ngot: %q", k, wantMsg, gotMsg)
				}
			}

			// Also check if got has any unexpected keys
			for k := range got {
				if _, ok := tc.VErrs[k]; !ok {
					t.Errorf("got unexpected error key %q with message %q", k, got[k])
				}
			}
		})
	}
}

type MockSESClient struct {
	ReturnOutput *awsses.UpdateConfigurationSetSendingEnabledOutput
	ReturnErr    error
}

func (s *MockSESClient) UpdateConfigurationSetSendingEnabled(ctx context.Context, input *awsses.UpdateConfigurationSetSendingEnabledInput, opts ...func(*awsses.Options)) (*awsses.UpdateConfigurationSetSendingEnabledOutput, error) {
	return s.ReturnOutput, s.ReturnErr
}

type MockSNSClient struct {
	ConfirmSubscriptionErr error
}

func (c *MockSNSClient) ConfirmSubscription(ctx context.Context, params *sns.ConfirmSubscriptionInput, optFns ...func(*sns.Options)) (*sns.ConfirmSubscriptionOutput, error) {
	if c.ConfirmSubscriptionErr != nil {
		return &sns.ConfirmSubscriptionOutput{}, c.ConfirmSubscriptionErr
	}
	return &sns.ConfirmSubscriptionOutput{
		SubscriptionArn: params.TopicArn,
	}, nil
}

func TestHandleSNSRequest(t *testing.T) {
	t.Run("valid subscription request", func(t *testing.T) {
		arn := "arn:aws:sns:us-east-1:123456789012:MyTopic"
		msg, ts := newSignedMessage(t, arn)
		defer ts.Close()

		// Extract host+port to make sure the domain check passes
		u, err := url.Parse(ts.URL)
		if err != nil {
			t.Fatal("problem with the test; httptest server URL not valid")
		}
		hostPort := u.Host

		rec := httptest.NewRecorder()

		sesclient := MockSESClient{}
		snsclient := MockSNSClient{}

		body, err := json.Marshal(msg)
		if err != nil {
			t.Fatal("error marshalling test request JSON. This is a problem with the test.", err)
		}

		req, err := http.NewRequest("POST", "localhost/brokerpaks/ses/reputation-alarm", bytes.NewReader(body))
		if err != nil {
			t.Fatal("error creating the test HTTP request. This is a problem with the test.", err)
		}
		req.Header.Add("x-amz-sns-message-type", "SubscriptionConfirmation")

		ses.HandleSNSRequest(slog.Default(), &sesclient, &snsclient, arn, hostPort).ServeHTTP(rec, req)
		if code := rec.Result().StatusCode; code != http.StatusOK {
			t.Fatalf("expected HTTP status %v, got %v", http.StatusOK, code)
		}
	})
}
