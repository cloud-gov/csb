package ses

import (
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
)

var (
	ErrSNSUnsupportedSignatureVersion = errors.New("sns: unsupported signature version")
	ErrSNSMissingSigningCertURL       = errors.New("sns: missing signing cert URL")
	ErrSNSMalformedSigningCertURL     = errors.New("sns: error parsing signing URL")
	ErrSNSWrongSigningCertDomain      = errors.New("sns: unexpected signing domain")
	ErrSNSPEMDecode                   = errors.New("sns: failed to decode PEM block from certificate")
	ErrSNSPublicKeyRSA                = errors.New("sns: certificate public key is not RSA")
	ErrSNSSignatureVerification       = errors.New("sns: signature verification failed")
	ErrSNSWrongTopicARN               = errors.New("sns: unexpected topic ARN")
)

// SNSMessage represents the fields from an SNS JSON message.
// Message formats are described here: https://docs.aws.amazon.com/sns/latest/dg/sns-message-and-json-formats.html
type SNSMessage struct {
	Message          string
	MessageId        string
	Signature        string
	SignatureVersion string
	SigningCertURL   string
	Subject          string
	SubscribeURL     string
	Timestamp        string
	Token            string
	TopicArn         string
	Type             string
}

// VerifySNSMessage fetches the certificate from SigningCertURL, builds the "string to sign",
// and verifies the signature using the public key.
// Signature verification is based on [AWS documentation].
// In addition to the steps described by AWS, the function also checks that the topic ARN in the message matches the arn that the application expects.
//
// [AWS documentation]: https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message-verify-message-signature.html
func VerifySNSMessage(msg SNSMessage, snsdomain string, arn string) error {
	slog.Info(fmt.Sprintf("Verifying signature of message: %+v", msg))
	if msg.SignatureVersion != "1" {
		return ErrSNSUnsupportedSignatureVersion
	}
	if msg.SigningCertURL == "" {
		return ErrSNSMissingSigningCertURL
	}

	// Ensure SigningCertURL is from a trusted domain
	u, err := url.Parse(msg.SigningCertURL)
	if err != nil {
		return ErrSNSMalformedSigningCertURL
	}
	if !strings.EqualFold(u.Host, snsdomain) {
		// Ensure an attacker hasn't sent us a message with non-AWS SigningCertURL
		return fmt.Errorf("wanted %v, got %v: %w", snsdomain, u.Host, ErrSNSWrongSigningCertDomain)
	}

	// Fetch the signing certificate
	certResp, err := http.Get(msg.SigningCertURL)
	if err != nil {
		return err
	}
	defer certResp.Body.Close()

	certBytes, err := io.ReadAll(certResp.Body)
	if err != nil {
		return err
	}

	// Parse the certificate
	block, _ := pem.Decode(certBytes)
	if block == nil {
		return ErrSNSPEMDecode
	}
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return err
	}

	// Decode the SNS signature
	signature, err := base64.StdEncoding.DecodeString(msg.Signature)
	if err != nil {
		return err
	}

	toSign := buildStringToSign(msg)
	slog.Info(fmt.Sprintf("string to sign: \n%v", toSign))
	// Check the decoded signature
	err = cert.CheckSignature(x509.SHA1WithRSA, []byte(toSign), signature)
	if err != nil {
		return fmt.Errorf("%w: %w", ErrSNSSignatureVerification, err)
	}

	// The message is authentically from SNS. Check if it's for the expected topic.
	if !strings.EqualFold(msg.TopicArn, arn) {
		return fmt.Errorf("wanted topic ARN %v, got %v: %w", arn, msg.TopicArn, ErrSNSWrongTopicARN)
	}

	return nil
}

// buildStringToSign constructs the correct string to sign based on the message type.
// AWS docs: https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message-verify-message-signature.html
func buildStringToSign(msg SNSMessage) string {
	// Notification
	if msg.Type == "Notification" {
		var sb strings.Builder
		sb.WriteString("Message\n")
		sb.WriteString(msg.Message)
		sb.WriteString("\nMessageId\n")
		sb.WriteString(msg.MessageId)
		if msg.Subject != "" {
			sb.WriteString("\nSubject\n")
			sb.WriteString(msg.Subject)
		}
		sb.WriteString("\nTimestamp\n")
		sb.WriteString(msg.Timestamp)
		sb.WriteString("\nTopicArn\n")
		sb.WriteString(msg.TopicArn)
		sb.WriteString("\nType\n")
		sb.WriteString(msg.Type)
		return sb.String()
	}

	// SubscriptionConfirmation or UnsubscribeConfirmation
	if msg.Type == "SubscriptionConfirmation" || msg.Type == "UnsubscribeConfirmation" {
		var sb strings.Builder
		sb.WriteString("Message\n")
		sb.WriteString(msg.Message)
		sb.WriteString("\nMessageId\n")
		sb.WriteString(msg.MessageId)
		sb.WriteString("\nSubscribeURL\n")
		sb.WriteString(msg.SubscribeURL)
		sb.WriteString("\nTimestamp\n")
		sb.WriteString(msg.Timestamp)
		sb.WriteString("\nToken\n")
		sb.WriteString(msg.Token)
		sb.WriteString("\nTopicArn\n")
		sb.WriteString(msg.TopicArn)
		sb.WriteString("\nType\n")
		sb.WriteString(msg.Type)
		return sb.String()
	}

	// Default fallback (should not happen since we handle all known types)
	return ""
}
