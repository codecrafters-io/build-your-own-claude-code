// Course-supplied transport; the agent owns document state and tool results.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

type LSPClient struct {
	url    string
	client *http.Client
}

func NewLSPClient() (*LSPClient, error) {
	url := os.Getenv("CODECRAFTERS_LSP_URL")
	if url == "" {
		return nil, fmt.Errorf("run with the course LSP transport")
	}
	return &LSPClient{url, &http.Client{Timeout: 10 * time.Second}}, nil
}

func (l *LSPClient) Call(action string, payload any) (json.RawMessage, error) {
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	response, err := l.client.Post(l.url+"/"+action, "application/json", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	data, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}
	if response.StatusCode != 200 {
		return nil, fmt.Errorf("LSP transport: %s", data)
	}
	return json.RawMessage(data), nil
}
