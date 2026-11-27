// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts.
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

// LSPClient sends your agent's messages to the language server.
//
// The client doesn't track open documents or versions; that state belongs in
// your agent.
//
// Example:
//
//	lsp, err := LSPClientFromEnvironment()
//	if err != nil {
//		log.Fatal(err)
//	}
//	if lsp != nil {
//		language := lsp.ExtensionToLanguage[".py"] // "python"
//		result, err := lsp.Call("request", map[string]any{"method": "textDocument/definition", "params": params})
//	}
type LSPClient struct {
	url    string
	client *http.Client
	// ExtensionToLanguage maps file extensions, including the dot, to LSP
	// language IDs, such as {".py": "python"}.
	ExtensionToLanguage map[string]string `json:"extensionToLanguage"`
}

// LSPClientFromEnvironment connects to the language server the tester
// configured. It returns nil and no error when no language server is configured.
func LSPClientFromEnvironment() (*LSPClient, error) {
	if _, configured := os.LookupEnv("CODECRAFTERS_LSP_URL"); !configured {
		return nil, nil
	}
	return NewLSPClient()
}

// NewLSPClient connects and reads the extension-to-language mapping.
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

// Call sends one action to the language server. The payload is marshaled to
// JSON, and Call returns the raw JSON response for you to unmarshal.
//
// Actions and their payloads:
//   - "configuration": {}. Returns {"extensionToLanguage": {".py": "python"}}.
//   - "notify": {"method": ..., "params": {...}}, an LSP notification.
//     Returns null.
//   - "request": {"method": ..., "params": {...}}, an LSP request. Returns the
//     server's result, which may be null, an object, or an array.
//   - "notifications": {"after": cursor, "timeoutMs": ms}. Returns
//     {"cursor": n, "notifications": [...]}: the server's notifications after
//     the cursor, each with "method" and "params". Waits up to ms (0 to 5000)
//     when none are queued yet. Pass the returned cursor as "after" next time.
//
// Call returns an error when the language server returns an error, times out
// (5 seconds for a request), or exits. Its message starts with "LSP transport:"
// and holds the transport's JSON, such as {"error":"language server exited before responding to textDocument/definition"}.
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
