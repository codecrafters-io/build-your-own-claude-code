// Package lsp_transport supplies wire transport, not agent tools or document state.
package main

import (
	"bufio"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type Notification struct {
	Method string          `json:"method"`
	Params json.RawMessage `json:"params"`
}

type Transport struct {
	URL           string
	command       *exec.Cmd
	input         io.WriteCloser
	output        io.ReadCloser
	server        *http.Server
	mu            sync.Mutex
	writeMu       sync.Mutex
	nextID        int
	pending       map[string]chan Message
	notifications []Notification
	changed       chan struct{}
	failure       error
	done          chan struct{}
	closeOnce     sync.Once
}

// Start owns one configured server until Close. The HTTP facade is course scaffolding.
func Start(configurationPath string) (*Transport, error) {
	root, err := filepath.Abs(filepath.Dir(configurationPath))
	if err != nil {
		return nil, err
	}
	root, err = filepath.EvalSymlinks(root)
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(configurationPath)
	if err != nil {
		return nil, err
	}
	var configurations map[string]struct {
		Command string   `json:"command"`
		Args    []string `json:"args"`
	}
	if err = json.Unmarshal(data, &configurations); err != nil {
		return nil, err
	}
	if len(configurations) != 1 {
		return nil, fmt.Errorf("expected one server in %s", configurationPath)
	}
	t := &Transport{pending: map[string]chan Message{}, changed: make(chan struct{}), done: make(chan struct{})}
	for _, configuration := range configurations {
		t.command = exec.Command(configuration.Command, configuration.Args...)
	}
	t.command.Dir = root
	t.command.Stderr = os.Stderr
	if t.input, err = t.command.StdinPipe(); err != nil {
		return nil, err
	}
	if t.output, err = t.command.StdoutPipe(); err != nil {
		t.input.Close()
		return nil, err
	}
	if err = t.command.Start(); err != nil {
		t.input.Close()
		t.output.Close()
		return nil, err
	}
	go t.read()
	go func() { t.command.Wait(); close(t.done) }()
	_, err = t.request("initialize", map[string]any{"processId": os.Getpid(), "rootUri": URI(root), "workspaceFolders": []map[string]string{{"uri": URI(root), "name": filepath.Base(root)}}, "capabilities": map[string]any{"textDocument": map[string]any{"publishDiagnostics": map[string]any{"versionSupport": true}}}})
	if err == nil {
		err = t.send("initialized", map[string]any{}, 0)
	}
	if err != nil {
		t.Close()
		return nil, err
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Close()
		return nil, err
	}
	secret := make([]byte, 24)
	if _, err = rand.Read(secret); err != nil {
		listener.Close()
		t.Close()
		return nil, err
	}
	path := "/" + hex.EncodeToString(secret)
	t.URL = "http://" + listener.Addr().String() + path
	mux := http.NewServeMux()
	mux.HandleFunc(path+"/", func(w http.ResponseWriter, r *http.Request) { t.serve(w, r, strings.TrimPrefix(r.URL.Path, path+"/")) })
	t.server = &http.Server{Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go t.server.Serve(listener)
	return t, nil
}

func (t *Transport) read() {
	reader := bufio.NewReader(t.output)
	for {
		message, err := ReadMessage(reader)
		t.mu.Lock()
		if err != nil {
			t.failure = err
			close(t.changed)
			t.changed = make(chan struct{})
			t.mu.Unlock()
			return
		}
		if message.Method != "" && len(message.ID) == 0 {
			t.notifications = append(t.notifications, Notification{Method: message.Method, Params: message.Params})
			close(t.changed)
			t.changed = make(chan struct{})
		} else if channel := t.pending[string(message.ID)]; channel != nil {
			channel <- message
		}
		t.mu.Unlock()
		// Servers may ask for workspace configuration. This extension uses no settings.
		if message.Method != "" && len(message.ID) != 0 {
			var result any
			if message.Method == "workspace/configuration" {
				var params struct {
					Items []any `json:"items"`
				}
				json.Unmarshal(message.Params, &params)
				result = make([]any, len(params.Items))
			}
			t.writeMu.Lock()
			WriteMessage(t.input, map[string]any{"jsonrpc": "2.0", "id": message.ID, "result": result}, false)
			t.writeMu.Unlock()
		}
	}
}

func (t *Transport) send(method string, params any, id int) error {
	message := map[string]any{"jsonrpc": "2.0", "method": method, "params": params}
	if id != 0 {
		message["id"] = id
	}
	t.writeMu.Lock()
	defer t.writeMu.Unlock()
	return WriteMessage(t.input, message, false)
}

func (t *Transport) request(method string, params any) (json.RawMessage, error) {
	t.mu.Lock()
	t.nextID++
	id := t.nextID
	key := fmt.Sprint(id)
	channel := make(chan Message, 1)
	t.pending[key] = channel
	t.mu.Unlock()
	defer func() { t.mu.Lock(); delete(t.pending, key); t.mu.Unlock() }()
	if err := t.send(method, params, id); err != nil {
		return nil, err
	}
	timer := time.NewTimer(5 * time.Second)
	defer timer.Stop()
	select {
	case message := <-channel:
		if len(message.Error) != 0 {
			return nil, fmt.Errorf("language server: %s", message.Error)
		}
		return message.Result, nil
	case <-t.done:
		return nil, fmt.Errorf("language server exited before responding to %s", method)
	case <-timer.C:
		return nil, fmt.Errorf("timed out waiting for %s", method)
	}
}

func (t *Transport) serve(w http.ResponseWriter, r *http.Request, action string) {
	w.Header().Set("Content-Type", "application/json")
	var body struct {
		Method    string          `json:"method"`
		Params    json.RawMessage `json:"params"`
		After     int             `json:"after"`
		TimeoutMS int             `json:"timeoutMs"`
	}
	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"POST required"}`, 405)
		return
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4*1024*1024)).Decode(&body); err != nil {
		http.Error(w, `{"error":"invalid JSON"}`, 400)
		return
	}
	var result any
	var err error
	switch action {
	case "request":
		result, err = t.request(body.Method, body.Params)
	case "notify":
		err = t.send(body.Method, body.Params, 0)
	case "notifications":
		if body.After < 0 || body.TimeoutMS < 0 || body.TimeoutMS > 5000 {
			http.Error(w, `{"error":"invalid notification cursor or timeout"}`, 400)
			return
		}
		t.mu.Lock()
		if body.After > len(t.notifications) {
			t.mu.Unlock()
			http.Error(w, `{"error":"cursor is ahead of stream"}`, 400)
			return
		}
		if body.After == len(t.notifications) && t.failure == nil && body.TimeoutMS > 0 {
			changed := t.changed
			t.mu.Unlock()
			timer := time.NewTimer(time.Duration(body.TimeoutMS) * time.Millisecond)
			select {
			case <-changed:
			case <-timer.C:
			case <-r.Context().Done():
			}
			timer.Stop()
			t.mu.Lock()
		}
		batch := append([]Notification{}, t.notifications[body.After:]...)
		result = map[string]any{"cursor": len(t.notifications), "notifications": batch}
		if len(batch) == 0 && t.failure != nil {
			err = t.failure
		}
		t.mu.Unlock()
	default:
		http.Error(w, `{"error":"unknown transport action"}`, 404)
		return
	}
	if err != nil {
		w.WriteHeader(502)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}
	json.NewEncoder(w).Encode(result)
}

func (t *Transport) Close() {
	t.closeOnce.Do(func() {
		if t.server != nil {
			t.server.Close()
		}
		t.input.Close()
		select {
		case <-t.done:
		case <-time.After(2 * time.Second):
			t.command.Process.Kill()
			<-t.done
		}
		t.output.Close()
	})
}

// Run wraps any course-language executable and exposes the initialized transport.
func Run(args []string) int {
	if len(args) < 3 || args[1] != "--" {
		fmt.Fprintln(os.Stderr, "usage: lsp-transport .lsp.json -- ./your_program.sh -p PROMPT")
		return 1
	}
	t, err := Start(args[0])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	defer t.Close()
	command := exec.Command(args[2], args[3:]...)
	command.Env = append(os.Environ(), "CODECRAFTERS_LSP_URL="+t.URL)
	command.Stdin, command.Stdout, command.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := command.Run(); err != nil {
		if exit, ok := err.(*exec.ExitError); ok {
			return exit.ExitCode()
		}
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	return 0
}
