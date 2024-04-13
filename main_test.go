package main

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

func TestMain(t *testing.T) {
	_, cancel := context.WithCancel(context.Background())
	t.Log("Starting server...")
	go func() {
		main()
	}()
	defer cancel()

	// give it time to start
	time.Sleep(1 * time.Second)
	// but retry a few times if we fail
	retries := 5
	wait := 2 * time.Second

	for i := 0; i < retries; i++ {
		t.Logf("Attempt %d/%d", i+1, retries)
		// send a curl request to the server
		url := fmt.Sprintf("http://localhost:%s", portDefault)
		req, err := http.NewRequest("GET", url, nil)
		require.NoError(t, err)

		client := &http.Client{}
		resp, err := client.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		if resp.StatusCode == http.StatusServiceUnavailable {
			t.Logf("Server not ready, retrying in %v...", wait)
			time.Sleep(wait)
			continue
		}

		t.Logf("Status code: %v", resp.StatusCode)
		require.Equal(t, http.StatusOK, resp.StatusCode)

		// body, err := io.ReadAll(resp.Body)
		// require.NoError(t, err)
		// t.Logf("Request received:\n%s", string(body))
		break
	}
}
