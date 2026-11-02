# Optional: what the connection helper does

You don't need this material to complete the five graded stages. Inspect
transport.go and protocol.go to see the server lifecycle and framing code.

The helper reads one named server configuration from .lsp.json:

```json
{
  "python": {
    "command": "pyright-langserver",
    "args": ["--stdio"],
    "extensionToLanguage": { ".py": "python" }
  }
}
```

It starts that command with its arguments, opens pipes, and sends initialize
with its own process ID and the project's encoded file URI. After reading a
successful matching response, it sends initialized. A failed handshake prevents
your agent from starting with a broken connection.

Each JSON-RPC message is UTF-8, preceded by Content-Length and a blank line:

```text
Content-Length: <number of JSON bytes>\r\n\r\n<JSON body>
```

Lengths count body bytes. A stream read may contain part of a message or several
messages, so the reader retains boundaries. Request IDs match responses;
notifications have no request ID and remain available in the helper's queue.

The local HTTP facade exposes these transport operations to every course
language. It doesn't decide which document to open or which result the model
should see. Those are the learner's integration tasks.

On completion the helper closes server stdin and waits, killing the child if it
doesn't exit within the cleanup deadline. A full editor client can also implement
shutdown/exit. The supplied fixture exits when stdin closes.
