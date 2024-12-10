package main

import (
	"context"
	"fmt"

	"github.com/cloudfoundry/go-cfclient/v3/client"
	"github.com/cloudfoundry/go-cfclient/v3/config"
)

func run() error {
	// Use CF client to get information about a service instance
	// Get services created by the CSB - filter by
	// Use client to upgrade a service
	// Create timer to upgrade periodically

	// Simple version upgrades all instances every day, just to be safe.
	// Less simple version checks to see if they need an upgrade based on plan
	// hash or similar.
	cfg, err := config.NewFromCFHome()
	if err != nil {
		return err
	}
	cf, err := client.New(cfg)
	if err != nil {
		return err
	}
	// todo: Filter by tag = csb
	instances, _, err := cf.ServiceInstances.List(context.Background(), nil)
	if err != nil {
		return err
	}
	// how to update each without doing it all at once? and how to keep track of updates and log if they go wrong?
	fmt.Println(instances[0].Name)
	return nil
}

func main() {
	err := run()
	if err != nil {
		panic(err)
	}
}
