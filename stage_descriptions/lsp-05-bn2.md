In this stage, you'll synchronize `Write` edits so definition and reference
lookups use the updated code.

### Why is the answer still pointing to the old file?

Suppose definition lookup on checkout's `invoice_total` call points to
`pricing.total`. The model then changes the import from `pricing` to `discounts`,
keeping the alias and call unchanged. The same lookup should now point to
`discounts.total`.

Saving updates the file on disk. The language server also needs its new contents
through the existing client; otherwise, it can keep answering from the old code.

Add this guidance to your system prompt:

```text
Edit files with Write so the language server sees changes.
```

### Track each document's state

Replace Stage 3's set of opened URIs with a map from URI to document version.
Keep this map beside the client, outside the agent loop, and share it between
navigation and Write. A URI in the map is open; a URI absent from it is closed.
Reuse navigation's path resolution and URI builder in Write so both handlers
find the same record.

Whenever either handler successfully sends `didOpen`, record version 1.
Each URI has its own version counter. Reading a file with Read, or receiving
its location in an LSP result, doesn't open it in the language server.

### Add synchronization to Write

For a Write to a file supported by the client's language mapping (`.py` maps to
`python` in this exercise):

1. Save the file using your existing Write handler.
2. After the save succeeds, send its complete new contents through `notify`.
   For an open URI, send `didChange` with its recorded version plus one.
   For a closed URI, reuse Stage 3's `didOpen` payload with its URI, mapped
   language ID, version 1, and complete new contents.
3. Wait for the notification call to complete, record the sent version in the
   shared map, then return Write's tool result. Use `await` with asynchronous
   clients.

Finish synchronization before the model's next lookup on the same connection.

### Synchronize a Write to an open document

If `checkout.py` is open at version 1, changing its import to `discounts` requires
this [didChange notification][did-change]. After saving, send it through `notify`
using your language's client-call pattern from Stage 3:

```json
{
  "method": "textDocument/didChange",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py", "version": 2 },
    "contentChanges": [{ "text": "from discounts import total as invoice_total\n\n\ndef checkout_total() -> int:\n    return invoice_total(250, 2)\n" }]
  }
}
```

The server uses full synchronization: `contentChanges` contains one object with
the complete text that was saved, including line breaks. No diff or edit range
is needed. A further Write to this document uses version 3.

### Synchronize a Write to a closed document

A references request on `pricing.py` can discover uses in `reports.py` without
opening it. After Write edits that closed file, sending `didOpen` refreshes any
previously indexed contents. This keeps later references current even when the
query targets another file.

### Tests

Run `codecrafters test`. The tester changes checkout's import using Write and
repeats definition lookup at the same position. The target must change from
`pricing.total` to `discounts.total`. Return each location through your existing
tool-result flow.

Additional cases check repeated versions and Write before the first lookup.
All cases use successful writes to supported Python files.

Your agent now keeps navigation results current after Write edits.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange

