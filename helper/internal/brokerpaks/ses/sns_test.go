package ses_test

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"math/big"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"

	"github.com/cloud-gov/csb/helper/internal/brokerpaks/ses"
)

func errNil(t *testing.T, err error) {
	if err != nil {
		t.Fatal("expected nil error")
	}
}

func errNotNil(t *testing.T, err error) {
	if err == nil {
		t.Fatal("expected non-nil error")
	}
}

func errIs(t *testing.T, actual, expected error) {
	if !errors.Is(actual, expected) {
		t.Fatalf("expected error %v, got %v", expected, actual)
	}
}

var stringToSign = `Message
Hello
MessageId
mid
Subject
subject
Timestamp
2021-01-01T00:00:00Z
TopicArn
arn:aws:sns:us-east-1:123456789012:MyTopic
Type
Notification
`

// newSignedMessage creates a new signed SNSMessage and an httptest.Server that serves the signing certificate. The TopicARN will be populated with arn. The caller is responsible for calling Close on the test server.
func newSignedMessage(t *testing.T, arn string) (ses.SNSMessage, *httptest.Server) {
	// 1. Generate an RSA key pair
	privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
	errNil(t, err)

	// 2. Create a self-signed certificate
	template := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
		KeyUsage:     x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		Subject:      pkix.Name{CommonName: "Test Cert"},
	}
	derBytes, err := x509.CreateCertificate(rand.Reader, template, template, &privateKey.PublicKey, privateKey)
	errNil(t, err)

	// 3. Encode cert to PEM
	certPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: derBytes})

	// 4. Serve the certificate via httptest.Server
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write(certPEM)
	}))

	// 5. Create an SNSMessage to verify
	testMsg := ses.SNSMessage{
		Type:             "Notification",
		MessageId:        "mid",
		Message:          "Hello",
		Subject:          "subject",
		Timestamp:        "2021-01-01T00:00:00Z",
		TopicArn:         arn,
		SignatureVersion: "1",
		SigningCertURL:   ts.URL, // must match domain check below
	}

	// 6. Hash and sign the known good string-to-sign
	hashed := sha1.Sum([]byte(stringToSign))
	signature, err := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA1, hashed[:])
	errNil(t, err)

	// 7. Put the signature in base64 form in the message
	testMsg.Signature = base64.StdEncoding.EncodeToString(signature)

	return testMsg, ts
}

// TestVerifySNSMessage tests certificate fetching, domain checks, and signature verification.
func TestVerifySNSMessage(t *testing.T) {
	t.Run("SignatureVersion not 1 => error", func(t *testing.T) {
		msg := ses.SNSMessage{
			SignatureVersion: "2",
		}
		err := ses.VerifySNSMessage(msg, "sns.example.com", "")
		errIs(t, err, ses.ErrSNSUnsupportedSignatureVersion)
	})

	t.Run("Missing signing cert URL => error", func(t *testing.T) {
		msg := ses.SNSMessage{
			SignatureVersion: "1",
		}
		err := ses.VerifySNSMessage(msg, "sns.example.com", "")
		errIs(t, err, ses.ErrSNSMissingSigningCertURL)
	})

	t.Run("SigningCertURL domain mismatch => error", func(t *testing.T) {
		msg := ses.SNSMessage{
			SignatureVersion: "1",
			SigningCertURL:   "https://malicious.com/cert.pem",
		}
		err := ses.VerifySNSMessage(msg, "sns.example.com", "")
		errIs(t, err, ses.ErrSNSWrongSigningCertDomain)
	})

	t.Run("Fail to GET certificate => error", func(t *testing.T) {
		// Use a localhost URL that isn't actually served.
		msg := ses.SNSMessage{
			SignatureVersion: "1",
			SigningCertURL:   "http://127.0.0.1:9999/cert.pem",
		}
		err := ses.VerifySNSMessage(msg, "127.0.0.1:9999", "")
		errNotNil(t, err)
	})

	t.Run("ARN mismatch => error", func(t *testing.T) {
		arn := "arn:aws:sns:us-east-1:123456789012:MyTopic"
		msg, ts := newSignedMessage(t, arn)
		defer ts.Close()

		// Extract host+port to make sure the domain check passes
		u, err := url.Parse(ts.URL)
		if err != nil {
			t.Fatal("problem with the test; httptest server URL not valid")
		}
		hostPort := u.Host

		err = ses.VerifySNSMessage(msg, hostPort, "bad arn")
		errIs(t, err, ses.ErrSNSWrongTopicARN)
	})

	t.Run("Valid signature and ARN => success", func(t *testing.T) {
		arn := "arn:aws:sns:us-east-1:123456789012:MyTopic"

		msg, ts := newSignedMessage(t, arn)
		defer ts.Close()

		// Extract host+port to make sure the domain check passes
		u, err := url.Parse(ts.URL)
		if err != nil {
			t.Fatal("problem with the test; httptest server URL not valid")
		}
		hostPort := u.Host

		// Confirm the message verifies without error
		err = ses.VerifySNSMessage(msg, hostPort, arn)
		errNil(t, err)
	})
}

const mockCertPEM = `-----BEGIN CERTIFICATE-----
MIIDyzCCArOgAwIBAgIJALB7yqMHd4s7MA0GCSqGSIb3DQEBCwUAMHoxCzAJBgNVBAYT
AlVTMRcwFQYDVQQIDA5Tb21lLVN0YXRlLU5hbWUxEzARBgNVBAcMClNvbWUtQ2l0eTEg
MB4GA1UECgwXU29tZSBPcmdhbml6YXRpb24gTmFtZTEUMBIGA1UECwwLU29tZS1Vbml0
MSMwIQYDVQQDDBpzb21lZG9tYWluLmF3c3Nucy5pbnRlcm5hbDAeFw0yNTAyMDUwMDAw
MDBaFw0zNTAyMDIwMDAwMDBaMHoxCzAJBgNVBAYTAlVTMRcwFQYDVQQIDA5Tb21lLVN0
YXRlLU5hbWUxEzARBgNVBAcMClNvbWUtQ2l0eTEgMB4GA1UECgwXU29tZSBPcmdhbml6
YXRpb24gTmFtZTEUMBIGA1UECwwLU29tZS1Vbml0MSMwIQYDVQQDDBpzb21lZG9tYWlu
LmF3c3Nucy5pbnRlcm5hbDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL3e
dwIa84YGUC223jE2ZHJE5kIc0OM5zYNQtcyHb63jDQ293Qq8JVV8FCkl17ULQ29EOcGg
bpGI0Gghhlk54s2QpCQE8yNg0o4mUhSRpFeVmy+jt2CJmyUfBEhBCi/HnqPNOWN0HG4w
6dEGmpeJvWg4Lr+LVsXIKbwQWR7T7ntEXCEEA2lC0zX0QTCMaV426V4DvqIGfU/Yx1Fd
Kuu8qKGhJ3QVrwTf2gnjI1OLQB/4gKknp9ma8E0pR4iFf9lR4cYZ9Q5XQOHjn3u81bIX
EqECFEjdHa/VG0T7GfjRVdoG1bc/Yr9vHFm8yak4LdSe7y/nSXFJS+Xp+CxBsiW/4wwf
XFzkuJsSpkQm7X/aN4MCAwEAAaNQME4wHQYDVR0OBBYEFDugmva7N31ao8/tA+NTU/4w
qfYtMB8GA1UdIwQYMBaAFDugmva7N31ao8/tA+NTU/4wqfYtMAwGA1UdEwQFMAMBAf8w
DQYJKoZIhvcNAQELBQADggEBAI7Ib+JQcpnUZjPLwwy7YX3Bcdsn9B2NIdHGKJPtuAeV
65FbFOuLsZyELPUXUp2bdYk+UXsNu/oYKhd/nHVcH3GqL4VFozBR7nYUdCh0UKIZGx18
tsqFjSz5aCKkJVayJFZH1v1uyGl2QLOrqT5LWzvyBmSphGtzrE8db46US+2v7RFkEpqz
jHVP5SWWSmPjlFCXQK+wlEilNLfwPary8U2ZpbnUD4YfcbP/RUMYc+aE4hX22ew6C5wn
h1TdKrhSQu7ZH7ou8FeIEywnUlJILkOYibRVUbNgeVePQF3p9YnSzZjVzXotGbuvj20K
q7eLOQb+NtMC9wMxqHaxC4k47XypPW330sA=
-----END CERTIFICATE-----`

// FuzzVerifySNSMessage fuzzes VerifySNSMessage to ensure it doesn’t panic.
func FuzzVerifySNSMessage(f *testing.F) {
	// A few seed inputs
	f.Add("Notification", "some msg", "msgid", "subject", "https://example.com/subscribe", "2025-02-05T12:34:56Z", "token123", "arn:aws:sns:us-east-1:123456789012:mytopic", "abc=", "1")
	f.Add("SubscriptionConfirmation", "", "", "", "", "", "", "", "", "1")

	// Set up a mock server that always returns mockCertPEM
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(mockCertPEM))
	}))
	defer ts.Close()

	f.Fuzz(func(t *testing.T,
		mType, message, messageID, subject, subscribeURL, timestamp, token, topicArn, signature, signatureVersion string,
	) {
		msg := ses.SNSMessage{
			Type:             mType,
			Message:          message,
			MessageId:        messageID,
			Subject:          subject,
			SubscribeURL:     subscribeURL,
			Timestamp:        timestamp,
			Token:            token,
			TopicArn:         topicArn,
			Signature:        signature,
			SignatureVersion: signatureVersion,
			// Point to our test server URL
			SigningCertURL: ts.URL,
		}

		// Drop the error, since we're only fuzzing for panics.
		_ = ses.VerifySNSMessage(msg, "example.com", "")
	})
}
