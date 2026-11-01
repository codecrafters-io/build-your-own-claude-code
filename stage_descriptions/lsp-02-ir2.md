In this stage, you'll handle the language server's response to `initialize`.

### Knowing when the server is ready

Sending `initialize` starts the conversation. Your agent still needs to know
whether startup succeeded and which features the server supports. The server's
reply provides both answers.

The server can also send log messages while starting up, so the next message
isn't necessarily the reply. You'll read complete messages, match the reply to
your request, and acknowledge a successful startup. This completes the
connection your agent will use for code queries in later stages.

### Reading a message

Read the reply from the server's stdout:

1. Read the header through the blank line (`\r\n\r\n`).
2. Parse `Content-Length` and read exactly that many bytes.
3. Decode the body as UTF-8 and parse its JSON.

A read can stop halfway through a body or include several messages. Keep unused
bytes for the next message. Report an error if stdout closes before the response
is complete.

### Responses and notifications

The
[initialization response](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initialize)
uses the request's `id`:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "capabilities": {
      "textDocumentSync": { "openClose": true, "change": 1 }
    }
  }
}
```

Match the `id` to your request and save `result.capabilities`. If the response
contains `error` instead of `result`, report the error and stop.

The server can also send startup logs before replying:

```json
{
  "jsonrpc": "2.0",
  "method": "window/logMessage",
  "params": { "type": 3, "message": "Starting the server" }
}
```

This is a **notification**. It has no `id` and needs no reply. Ignore
notifications for now and keep reading until you receive your response.

### Completing initialization

After the successful response, send:

```json
{ "jsonrpc": "2.0", "method": "initialized", "params": {} }
```

You can now send language-server queries. Keep this server process running for
the whole agent run so you can send it more requests in later stages.

Keep the cleanup from earlier stages: close stdin and wait on exit. A graceful
`shutdown` and `exit` exchange is also accepted.

### Tests

The tester will write `.lsp.json` and run:

```bash
$ ./your_program.sh -p "Reply with ready."
```

After the initialization response above, it expects:

```json
{ "jsonrpc": "2.0", "method": "initialized", "params": {} }
```

Your request IDs can differ. The tester also sends partial messages,
notifications, an initialization error, and an incomplete response. Failed
initialization must be reported and must not lead to `initialized` or document
queries.

### Notes

- The bytes go to your protocol reader, not your program's stdout.
- Assign each new request a unique ID and match responses by ID, rather than
  assuming the next message is the answer.
