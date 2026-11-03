# Advanced LSP helper usage

Optional reference for local servers, transport actions, and notifications.
For course setup, use the language-specific instructions in CodeCrafters.

## Select the analyzed language

The client is written in your agent's implementation language. The language it
analyzes comes from `.lsp.json`: `command` and `args` select the server, and
`extensionToLanguage` maps file extensions to document language IDs. There is no
fixed Python language in the helper and no language argument to the constructor.
The course tests configure Python; you can configure a different server locally.

Call action `configuration` with `{}` to read the configured mapping. The empty
object is the request's argument list, not a configuration you must fill in.
This action belongs to the course helper, not the LSP protocol. The response in
the course tests is:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

For a locally configured TypeScript server, the response could instead be:

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

After a C call returns NULL, `lsp_last_error()` exposes the helper's error text
until the next call. Zig exposes that text through `lsp.lastError()` after
`error.LSPTransportFailure`; use a mutable client and call `lsp.deinit()` on
exit. These error strings are borrowed; copy them into the tool result before
another call. For other Zig failures, use `@errorName(err)`.

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

## Optional: read server notifications

The five graded stages do not require reading server notifications. The final
capstone combines navigation, synchronized edits, and Bash test results to check
an API migration. The helper also exposes queued notifications for optional
advanced work, such as diagnostic feedback.

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

For optional diagnostic feedback after Write, drain pending messages before the
edit, then record the cursor. Save and synchronize the file. Poll after that
cursor until you receive a publication for its URI;
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
/tmp/lsp-transport .lsp.json -- /absolute/path/to/your_program.sh -p \
  "Change pricing.total to return a Price TypedDict with a cents field.
Use LSP to find the implementation and its callers. Edit files with Write.
Update checkout.py and reports.py so they still return integer cents.
Leave preview.total unchanged. Don't modify test_invoice.py.
Run python3 -m unittest -v test_invoice.py."
```

The standalone helper and tester use the same transport source. The helper reads
`.lsp.json`, starts its configured server in the working directory, initializes
it, launches your program with the connection URL, and cleans up afterward.
It binds only to loopback and uses an invocation-specific endpoint.

The optional [protocol walkthrough](lsp_transport/protocol-walkthrough.md)
explains the low-level initialization request hidden by the helper.
