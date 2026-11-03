In this stage, you'll synchronize `Write` edits to keep language-server answers current.

### Why is the answer still pointing to the old file?

After your agent changes checkout's import from `pricing` to `discounts`,
`invoice_total` should resolve to `discounts.total`. The server still sees the
contents sent through `didOpen` until you synchronize the edit.

Bash edits aren't synchronized in this stage. Keep this system-prompt guidance:
"Edit files with Write so the language server sees changes."

### Extend your Write handler

An **open document** is a URI you've successfully sent with `didOpen`.
Reading a file with Read does not open it in the language server.

Reuse navigation's URI builder and document tracking. For this open document:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

The model requests this Write:

```json
{"file_path":"checkout.py","content":"from discounts import total as invoice_total\n\n\ndef checkout_total() -> int:\n    return invoice_total(250, 2)\n"}
```

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
    "contentChanges": [{ "text": "from discounts import total as invoice_total\n\n\ndef checkout_total() -> int:\n    return invoice_total(250, 2)\n" }]
  }
}
```

The course server uses full synchronization, so send the entire file. You don't
need to calculate a diff. Extend your opened-document tracking from earlier stages to
store a version for each URI. `didOpen` uses version 1, followed by 2, 3, and so on.

After a successful Write to a supported closed file, send didOpen with its new
contents. References may have indexed it. Opening refreshes that copy even when
the next query targets another file. Record it as open at version 1 and wait for
notification completion here too. A supported file has an extension in setup's
mapping. Other files use ordinary Write without LSP notifications.

Don't notify after failed writes. Report synchronization failures in Write's
tool result. Reuse the supplied connection.

### Tests

The tester writes the invoice project and runs:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Use Write to change its import from pricing to discounts, preserving the invoice_total alias. Repeat definition lookup at the same position and report the new target."
```

The first LSP result must preserve:

```json
{"uri":"file:///project/pricing.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
```

After the successful Write, the second must preserve:

```json
{"uri":"file:///project/discounts.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
```

Substitute the actual project URI. Other cases restore the import, write before
lookup, and attempt a directory write. Failed writes must leave analysis unchanged.
The final explanation can vary.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
