In this stage, you'll start a language server and introduce your agent to it.

### Giving your agent code navigation

Your agent can already read files, but finding the function behind a call can
mean searching through several files. A **language server** analyzes a project
and can tell your agent where a function is defined and what types it expects.

Editors communicate with language servers through the
[Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
(LSP). In this extension, you'll give your agent access to that code information
too.

Before asking about code, your agent needs to tell the server which project to
analyze. In this stage, you'll start the server and send that information in an
`initialize` request. You'll handle its reply in the next stage.

### Start the configured server

Before starting your program, the tester creates `.lsp.json` in the project
directory and supplies a language server executable. You don't need to create
this file or install a server to run the automated tests. Your code reads the
file at runtime from its current working directory.

The file contains one server configuration, with this structure:

```json
{
  "python": {
    "command": "/path/to/language-server",
    "args": [],
    "extensionToLanguage": { ".py": "python" }
  }
}
```

This follows Claude Code's
[LSP server configuration](https://code.claude.com/docs/en/plugins/components#lsp-servers).

When your agent starts:

1. Read and parse `.lsp.json` in the current working directory.
2. Extract `command` and `args` from its single server configuration (the
   `python` entry in this example).
3. Start a child process using that command and those arguments, with the
   project directory as its working directory.

The command path above is a placeholder. This example has no arguments, but the
tester may supply them in `args`. Read both `command` and the complete `args`
array from the file, passing each argument unchanged and in order. The `.py`
mapping is for later stages. Your agent can be written in any course language.

Create pipes for the child's stdin and stdout: your agent writes requests to
the server's stdin and reads replies from its stdout. Inherit stderr so server
errors appear in the test logs. Use your language's subprocess API to start the
child and obtain these streams. There is no network port to connect to.

If `.lsp.json` is absent, continue handling prompts as before, without starting
a server.

### Introduce your agent

Send this JSON message to the server first:

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

You can use the shown `jsonrpc`, `id`, `method`, and empty `capabilities` values
as-is for this stage. The `id` identifies your request so you can recognize its
reply in the next stage.

Replace these two example values with values from your running program:

- `processId`: your agent's process ID, not the child server's ID.
- `rootUri`: the project's absolute file URI. Use your language's URI utilities
  to convert the current working directory, including encoding any spaces.

### Send the message

The server reads a stream of bytes, so it needs to know where each message ends.
LSP puts a `Content-Length` header before each JSON body:

```text
Content-Length: <number of JSON bytes>\r\n\r\n<JSON body>
```

Serialize your request as UTF-8 JSON, count the body's bytes, and put that count
in the header. Count bytes, not characters, and exclude the header itself.
Here, `\r\n` means actual carriage-return and newline bytes. Write the header
and body to the server's stdin, then flush so the message is sent immediately.

You don't need to read the reply yet. Keep the server running until your agent
finishes, then close its stdin and wait for it to exit.

To pass this stage, start the configured server and send one correctly framed
`initialize` request. You don't need to read its response or add an LSP tool
yet. Continue handling the prompt as usual.

### Tests

The automated course tests will create `.lsp.json`, supply a test server, and run:

```bash
$ ./your_program.sh -p "Reply with ready."
```

Even though this prompt doesn't ask about code, your agent should start the
configured server and send `initialize`. The tests check that it launches the
configured command with its arguments in the project directory, sends a
correctly framed request with your process ID and project URI, and cleans up
the server process when it finishes. The test server exits when stdin closes.

### Optional: test with a server locally

To try this outside the automated tests, install
[Pyright](https://github.com/microsoft/pyright), a Python language server. With
Node.js and npm installed, run:

```bash
npm install --global pyright@1.1.414
```

Create `.lsp.json` in the directory where you'll run your agent. Use the
configuration above with `command` set to `"pyright-langserver"` and `args` set
to `["--stdio"]`. Your agent will then start `pyright-langserver --stdio`.
These arguments are specific to Pyright; the automated test server uses its own.
Python is the language this server analyzes; your agent can use any course
language.
