In this stage, you'll send an `initialize` request to a language server.

### Giving your agent code navigation

An invoice for two 250-cent items prints `250250` instead of `500`. Your agent
must follow the imported name `invoice_total` and discover that the function
expects an integer price.

A **language server** analyzes code to provide definitions, types, and
references through the
[Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
(LSP). Claude Code uses this connection for navigation and type errors after
edits. You'll begin by telling the server which project to analyze.

### Starting the server

The tester will create `.lsp.json` in the project directory:

```json
{
  "python": {
    "command": "/path/to/language-server",
    "args": ["--stdio"],
    "extensionToLanguage": { ".py": "python" }
  }
}
```

The file uses Claude Code's
[LSP server configuration](https://code.claude.com/docs/en/plugins/components#lsp-servers).
Here, `.lsp.json` contains one server in the project root. Plugin installation
is outside this extension.

Start its `command` with `args` in the project directory. Pipe stdin and stdout,
and inherit stderr. The tester supplies the server. For these opening tests,
connect even when the prompt only asks for a reply.

### The `initialize` request

LSP uses
[JSON-RPC messages](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#baseProtocol).
Send `initialize` as the first request:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "processId": 1234,
    "rootUri": "file:///path/to/project",
    "capabilities": {}
  }
}
```

The fields you'll need are:

- `id`: Identifies the request so you can match the server's reply later.
- `processId`: Your program's process ID.
- `rootUri`: The project's absolute file URI.
- `capabilities`: The client features you support. Leave this empty for now.

Before writing the JSON to the server's stdin, add a header giving its length:

```text
Content-Length: <number of body bytes>\r\n\r\n<JSON body>
```

Encode the JSON as UTF-8 and count its bytes. Here, `\r\n` means actual
carriage-return and newline bytes. Flush stdin after writing the message.

### Tests

The tester will write `.lsp.json` and run:

```bash
$ ./your_program.sh -p "Reply with ready."
```

For process `1234` in `/path/to/project`, the server should receive:

```text
Content-Length: 128\r\n\r\n{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":1234,"rootUri":"file:///path/to/project","capabilities":{}}}
```

Use the process ID and project path from your run. JSON spacing can differ, but
the byte count must match. The tester also checks the launch arguments, process
cleanup, and behavior without configuration.

### Notes

- You don't need to read the reply yet. The test server sends a small response
  that fits in the pipe.
- When your program finishes, close the child's stdin and wait for it to exit.
  The supplied server exits on EOF. A completed client may also shut it down
  gracefully.
- Without `.lsp.json`, keep the base behavior.
