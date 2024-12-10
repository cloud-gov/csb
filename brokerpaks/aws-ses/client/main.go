package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/smtp"
	"os"
	"strings"
)

type VCAPServices struct {
	SMTPService []struct {
		Credentials Credentials `json:"credentials"`
	} `json:"aws-ses"`
}

type Credentials struct {
	Server    string `json:"smtp_server"`
	User      string `json:"smtp_user"`
	Password  string `json:"smtp_password"`
	DomainARN string `json:"domain_arn"`
}

func creds(configfile string) (Credentials, error) {
	// If a config file exists, load credentials from that.
	if f, err := os.ReadFile(configfile); err == nil {
		log.Printf("Loading credentials from config file %s", configfile)
		var creds Credentials

		err = json.Unmarshal(f, &creds)
		if err != nil {
			return Credentials{}, fmt.Errorf("unmarshalling config file [%s]: %w", configfile, err)
		}
		return creds, nil
	}

	// Otherwise, read from VCAP_SERVICES.
	log.Println("Loading credentials from VCAP_SERVICES")
	vcapServices := os.Getenv("VCAP_SERVICES")
	var services VCAPServices
	err := json.Unmarshal([]byte(vcapServices), &services)
	if err != nil {
		return Credentials{}, fmt.Errorf("unmarshalling VCAP_SERVICES: %w", err)
	}
	return services.SMTPService[0].Credentials, nil

}

func send(recipient string, creds Credentials) error {
	auth := smtp.PlainAuth("", creds.User, creds.Password, creds.Server)
	from := "csb@" + strings.Split(creds.DomainARN, "/")[1]
	to := recipient
	msg := fmt.Sprintf("From: %s\r\n", from) +
		fmt.Sprintf("To: %s\r\n", to) +
		"Subject: Hello, world!\r\n" +
		"\r\n" +
		"Sent from the CSB!\r\n"
	log.Println("Sending...")
	err := smtp.SendMail(
		fmt.Sprintf("%s:2587", creds.Server),
		auth,
		from,
		[]string{to},
		[]byte(msg),
	)
	return err
}

type config struct {
	Address    string
	Configpath string
	Recipient  string
}

func flags() (config, error) {
	addr := flag.String("address", ":8080", "TCP address the server will listen on. Examples: :8080, localhost:8080.")
	configpath := flag.String("config", "", "File system path to a JSON credentials file. The file must be structured as it would be in VCAP_SERVICES.")
	rcpt := flag.String("recipient", "", "Email address of the recipient.")

	flag.Parse()

	if *rcpt == "" {
		return config{}, fmt.Errorf("Error: Recipient missing. Provide the recipient email address. See --help.")
	}
	return config{
		Address:    *addr,
		Configpath: *configpath,
		Recipient:  *rcpt,
	}, nil
}

func run() error {
	config, err := flags()
	if err != nil {
		return err
	}

	creds, err := creds(config.Configpath)
	if err != nil {
		return fmt.Errorf("Loading credentials: %w", err)
	}

	http.HandleFunc("POST /send", func(w http.ResponseWriter, r *http.Request) {
		if err := send(config.Recipient, creds); err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "error sending: %s\n", err.Error())
		} else {
			w.WriteHeader(http.StatusOK)
			io.WriteString(w, "ok\n")
		}

	})
	log.Printf("Starting server on %s...\n", config.Address)
	return http.ListenAndServe(config.Address, nil)
}

func main() {
	// Start all real work in a function so it can return errors conventionally.
	// Centralize handling those errors here.
	err := run()
	if err != nil {
		log.Fatal(err)
	}
}
