# Supplied LSP connection

The five LSP stages teach the bridge between an existing agent and a language
server. The supplied helper owns subprocess startup, JSON-RPC framing,
initialization, request IDs, buffering, and cleanup. It does not open files,
synchronize edits, interpret diagnostics, choose repairs, or run an agent.

## Connect in one line

The tester starts one helper for each case and sets `CODECRAFTERS_LSP_URL` for
your program. Your starter includes a client in your implementation language:

| Language   | Client file                    | Connection                                                                                     |
| ---------- | ------------------------------ | ---------------------------------------------------------------------------------------------- |
| Python     | `app/lsp_client.py`            | `lsp = LSPClient()`                                                                            |
| JavaScript | `app/lsp_client.js`            | `const lsp = new LSPClient()`                                                                  |
| TypeScript | `app/lsp_client.ts`            | `const lsp = new LSPClient()`                                                                  |
| Go         | `app/lsp_client.go`            | `lsp, err := NewLSPClient()`                                                                   |
| Java       | `src/main/java/LSPClient.java` | `var lsp = new LSPClient()`                                                                    |
| C#         | `src/LSPClient.cs`             | `var lsp = new LSPClient()`                                                                    |
| C          | `src/lsp_client.h`             | `lsp_call(action, json)` reads the supplied URL                                                |
| C++        | `src/lsp_client.hpp`           | `LSPClient lsp;`                                                                               |
| Rust       | `src/lsp_client.rs`            | `let lsp = LspClient::new()?;`                                                                 |
| Zig        | `src/lsp_client.zig`           | `const lsp = try LSPClient.init(allocator, io, init.environ_map.get("CODECRAFTERS_LSP_URL"));` |

Import/include the supplied file in the usual way. JavaScript uses
`import { LSPClient } from "./lsp_client.js"`; Rust needs `mod lsp_client;`.
The starter's `lsp_tool.json` supplies the initial model-facing tool schema.
Setup only connects the client, reads configuration, and advertises this schema.
Definition calls begin in stage two. Add `findReferences` in stage three.

## Select the analyzed language

The client is written in your agent's implementation language. The language it
analyzes comes from `.lsp.json`: `command` and `args` select the server, and
`extensionToLanguage` maps file extensions to document language IDs. There is no
fixed Python language in the helper and no language argument to the constructor.
The course tests configure Python; you can configure a different server locally.

Call action `configuration` with `{}` to obtain the configured mapping. For a
TypeScript server, for example, the result could be:

```json
{ "extensionToLanguage": { ".ts": "typescript", ".tsx": "typescript" } }
```

Use the entry for the file's extension as `didOpen.textDocument.languageId`.
Report an unsupported file extension if it has no entry. The helper requires a
nonempty mapping; it does not guess a language or install a server.

## Transport actions

All clients provide `call(action, payload)` (capitalized `Call` in Go/C#).
Java, C#, C and Zig accept serialized JSON; their results are serialized JSON.
The other clients accept their language's JSON values. Go returns
`json.RawMessage`. C returns an allocated string: check for NULL, then free it.
Check the helper's error before using its result. JavaScript, TypeScript, and
C# calls are asynchronous.

Send a notification:

```json
{ "method": "textDocument/didOpen", "params": { "textDocument": {} } }
```

Use action `notify`; replace the document with the fields from the stage.
It returns null. For action `request`, send the same method/params envelope
with `textDocument/definition` or `textDocument/references`. The response is the
server's result, including null. Transport and protocol failures are errors.

The HTTP endpoint is course scaffolding around the stdio LSP connection, not a
part of LSP. The learner's model-facing LSP tool uses the product's one-based
positions; the server receives zero-based positions.

## Read notifications in stage five

Call action `notifications` with:

```json
{ "after": 0, "timeoutMs": 0 }
```

It returns all queued notifications after that cursor:

```json
{
  "cursor": 1,
  "notifications": [
    {
      "method": "textDocument/publishDiagnostics",
      "params": {
        "uri": "file:///project/checkout.py",
        "version": 2,
        "diagnostics": []
      }
    }
  ]
}
```

Save the returned cursor for the next call. `timeoutMs: 0` drains without waiting;
a value up to 5000 waits for messages. Notifications are retained while requests
are running. An empty notification batch is not a clean diagnostic report.

Before Write, drain pending messages, then record the cursor. Save and synchronize
the file. Poll after that cursor until you receive a publication for its URI;
ignore versioned reports older than the current document. Advance the cursor
even for unrelated notifications. Stop at an overall deadline and return a
feedback error on timeout. Accept unversioned publications in arrival order.
Your agent owns all of these decisions.

## Run with your own server

This optional activity needs Go 1.25+ to build the helper and a language server
installed locally. It isn't required for graded stages. From this repository:

```sh
(cd extension_helpers/lsp_transport && go build -o /tmp/lsp-transport .)
cd extension_designs/lsp_exercise
/tmp/lsp-transport .lsp.json -- /absolute/path/to/your_program.sh -p "Migrate pricing.total to a Price object with cents and update its callers. Use LSP navigation and Write feedback."
```

The standalone helper and tester use the same transport source. The helper reads
`.lsp.json`, starts its configured server in the working directory, initializes
it, launches your program with the connection URL, and cleans up afterward.
It binds only to loopback and uses an invocation-specific endpoint.

The optional [protocol walkthrough](lsp_transport/protocol-walkthrough.md)
explains the low-level initialization request hidden by the helper.
