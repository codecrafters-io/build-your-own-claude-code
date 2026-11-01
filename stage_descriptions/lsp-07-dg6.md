In this stage, you'll add support for language-server diagnostics.

### Diagnostics

Your `Write` tool tells the model whether a file was written. The language
server can also tell it whether the new code has errors.

These errors and warnings are called **diagnostics**. For example,
`invoice_total("250", 2)` passes a string where an integer is expected. The
server reports the problem in a
[`textDocument/publishDiagnostics`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_publishDiagnostics)
notification after `didOpen` or `didChange`:

```json
{
  "jsonrpc": "2.0",
  "method": "textDocument/publishDiagnostics",
  "params": {
    "uri": "file:///path/to/project/checkout.py",
    "version": 2,
    "diagnostics": [
      {
        "range": {
          "start": { "line": 4, "character": 25 },
          "end": { "line": 4, "character": 30 }
        },
        "severity": 1,
        "message": "Argument of type str cannot be assigned to parameter price of type int"
      }
    ]
  }
}
```

Like the log notifications you handled in earlier stages, this message has no
request ID. Update your reader to store its diagnostics by URI and keep handling
ordinary responses.

### Returning diagnostics

Add `"textDocument": {"publishDiagnostics": {"versionSupport": true}}` to your
initialization capabilities. Every diagnostic notification from the test server
includes the document's version.

Add a `diagnostics` operation to the LSP tool. It needs only `operation` and
`file_path`. Make `line` and `character` optional in the schema and validate
them for position-based operations.

When the model requests diagnostics, open the file if needed. Return the stored
list for its current version, or keep reading until that list arrives. Use a
timeout and return an error if it doesn't arrive.

Do the same after every successful `Write`, including the diagnostics in the
write's tool result. If the file wasn't open, first open it with its new text.
The model can then use the error message to make another edit.

Each new list replaces the old one for that URI. An empty list clears the old
errors. Ignore notifications for older versions.

### Tests

The tester will create a valid `checkout.py` and run:

```bash
$ ./your_program.sh -p 'Check diagnostics for checkout.py. Use Write to make invoice_total receive "250" instead of 250, then fix that argument using Write. Check the diagnostics returned by each write.'
```

Opening gives the file version `1`, followed by versions `2` and `3` for the
writes. Their tool results must contain the error above and then:

```json
{ "version": 3, "diagnostics": [] }
```

Your tool result can include other fields. The tester also sends diagnostics
between responses, before you start waiting, for older versions, and not at all.

### Notes

- Don't invent a `textDocument/diagnostics` request. This stage uses push
  notifications.
- The supplied server always publishes versioned diagnostics for each open and
  change. This is an exercise guarantee, not a guarantee made by every language
  server.
