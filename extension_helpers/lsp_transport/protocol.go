package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/url"
	"path/filepath"
	"strconv"
	"strings"
)

type Message struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method,omitempty"`
	Params  json.RawMessage `json:"params,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   json.RawMessage `json:"error,omitempty"`
}

func ReadMessage(reader *bufio.Reader) (Message, error) {
	length := -1
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			return Message{}, err
		}
		if line == "\r\n" {
			break
		}
		key, value, ok := strings.Cut(strings.TrimSuffix(line, "\r\n"), ":")
		if !ok {
			return Message{}, fmt.Errorf("invalid LSP header %q", line)
		}
		if strings.EqualFold(key, "Content-Length") {
			length, err = strconv.Atoi(strings.TrimSpace(value))
			if err != nil {
				return Message{}, fmt.Errorf("invalid Content-Length: %w", err)
			}
		}
	}
	if length < 0 || length > 4*1024*1024 {
		return Message{}, fmt.Errorf("invalid Content-Length %d", length)
	}
	body := make([]byte, length)
	if _, err := io.ReadFull(reader, body); err != nil {
		return Message{}, fmt.Errorf("incomplete LSP body: %w", err)
	}
	var message Message
	if err := json.Unmarshal(body, &message); err != nil {
		return Message{}, err
	}
	if message.JSONRPC != "2.0" {
		return Message{}, fmt.Errorf("expected jsonrpc 2.0")
	}
	return message, nil
}

func WriteMessage(writer io.Writer, value any, fragmented bool) error {
	body, err := json.Marshal(value)
	if err != nil {
		return err
	}
	frame := append([]byte(fmt.Sprintf("Content-Length: %d\r\n\r\n", len(body))), body...)
	for len(frame) > 0 {
		size := len(frame)
		if fragmented && size > 7 {
			size = 7
		}
		n, err := writer.Write(frame[:size])
		if err != nil {
			return err
		}
		if n == 0 {
			return io.ErrShortWrite
		}
		frame = frame[n:]
	}
	return nil
}

func URI(path string) string {
	return (&url.URL{Scheme: "file", Path: filepath.ToSlash(path)}).String()
}
