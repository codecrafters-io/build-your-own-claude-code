// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
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
	url                 string
	client              *http.Client
	ExtensionToLanguage map[string]string `json:"extensionToLanguage"`
}

func LSPClientFromEnvironment() (*LSPClient, error) {
	if _, configured := os.LookupEnv("CODECRAFTERS_LSP_URL"); !configured {
		return nil, nil
	}
	return NewLSPClient()
}

func NewLSPClient() (*LSPClient, error) {
	url := os.Getenv("CODECRAFTERS_LSP_URL")
	if url == "" {
		return nil, fmt.Errorf("run with the course LSP transport")
	}
	lsp := &LSPClient{url: url, client: &http.Client{Timeout: 10 * time.Second}}
	configuration, err := lsp.Call("configuration", map[string]any{})
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(configuration, lsp); err != nil {
		return nil, err
	}
	return lsp, nil
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
