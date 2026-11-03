In this stage, you'll keep language-server answers current after edits made
through Write.

### Why is the answer still pointing to the old file?

After your agent changes checkout's import from `pricing` to `discounts`,
`invoice_total` should resolve to `discounts.total`. The server still sees the
contents sent through `didOpen` until you synchronize the edit.

Bash edits aren't synchronized in this stage. Include this guidance in your
LSP tool description: "Edit files with Write so the language server sees changes."

### Extend your Write handler

An **open document** is a URI you've successfully sent with `didOpen`.
Reading a file with Read does not open it in the language server.

Reuse navigation's URI builder and document tracking.

After a successful write to an open document, send a
[didChange notification][did-change]:

1. Increment that URI's document version.
2. Send action `notify` with the complete object below, using your language's
   client-call pattern from definition lookup.
3. Wait for notification completion before returning Write's tool result or
   continuing the agent loop. Use `await` with asynchronous clients.

```json
{
  "method": "textDocument/didChange",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py", "version": 2 },
    "contentChanges": [{ "text": "<complete new file contents>" }]
  }
}
```

The course server uses full synchronization, so send the entire file. You don't
need to calculate a diff. Extend your opened-document tracking from stage 2 to
store a version for each URI. `didOpen` uses version 1, followed by 2, 3, and so on.

After a successful Write to a supported closed file, send didOpen with its new
contents. References may have indexed it; opening refreshes that copy even when
the next query targets another file. Record it as open at version 1 and wait for
notification completion here too. A supported file has an extension in setup's
mapping; other files use ordinary Write without LSP notifications.

Don't notify after failed writes. Report synchronization failures in Write's
tool result. Reuse the supplied connection.

### Tests

Run `codecrafters test`. It looks up a definition, changes the import with Write,
then repeats the lookup. The target must change from pricing to discounts and
back when restored. It also tests Write before lookup and a failed directory
write. Successful edits must update analysis; failed writes must leave it
unchanged.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
