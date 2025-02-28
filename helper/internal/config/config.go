package config

import (
	"fmt"
	"net/url"
	"os"
	"strconv"
)

type Config struct {
	// Host is the public URL for the application. Required for redirects to work.
	Host string
	// ListenAddr is the TCP address (without port) the process will bind to. For production, leave empty. For local development, use "localhost". Specify the port separately with [config.Port].
	ListenAddr string
	// Port is the TCP port the process will listen on. Specified separately because Cloud Foundry provides it to applications automatically.
	Port uint16
	// BrokerURL is the URL of the Cloud Service Broker instance that serves the documentation page.
	BrokerURL url.URL
	// PlatformNotificationsTopicARN is the ARN of an AWS SNS topic which the helper can subscribe to.
	PlatformNotificationsTopicARN string
}

func Load() (Config, error) {
	c := Config{}

	c.Host = os.Getenv("HOST")
	c.ListenAddr = os.Getenv("LISTEN_ADDR")

	port := os.Getenv("PORT")
	p, err := strconv.ParseUint(port, 10, 16)
	if err != nil {
		return Config{}, fmt.Errorf("invalid PORT: '%w'", err)
	}
	c.Port = uint16(p)

	brokerURL := os.Getenv("BROKER_URL")
	u, err := url.Parse(brokerURL)
	if err != nil {
		return Config{}, fmt.Errorf("invalid BROKER_URL: '%w'", err)
	}
	// Add a scheme and parse again, or else the URL will be parsed as relative and fields we need later, like Host, will be empty. See [url.Parse] docs.
	if u.Scheme == "" {
		brokerURL = "https://" + brokerURL
	}
	u, err = url.Parse(brokerURL)
	if err != nil {
		return Config{}, fmt.Errorf("invalid BROKER_URL: '%w'", err)
	}

	c.BrokerURL = *u

	n := os.Getenv("CG_PLATFORM_NOTIFICATION_TOPIC_ARN")
	if n == "" {
		return Config{}, fmt.Errorf("invalid CG_PLATFORM_NOTIFICATION_TOPIC_ARN: '%v'", n)
	}
	c.PlatformNotificationsTopicARN = n

	return c, nil
}
