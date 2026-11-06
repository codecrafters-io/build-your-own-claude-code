In this stage, you'll synchronize `Write` edits so definition and reference
lookups use the updated code.

### Why is the answer still pointing to the old file?

Suppose definition lookup on checkout's `invoice_total` call points to
`pricing.total`. The model then changes the import from `pricing` to `discounts`,
keeping the alias and call unchanged. The same lookup should now point to
`discounts.total`.

Saving updates the file on disk. The language server also needs its new contents
through the existing client; otherwise, it can keep answering from the old code.

Your system prompt should direct the model to use Write for edits, for example:

```text
Edit files with Write so the language server sees changes.
```

### Document synchronization

After a successful Write to a supported file, the server must receive its
complete saved contents through the client's `notify` action. The client's
language mapping identifies supported files (`.py` maps to `python` here).

The notification depends on whether the document is already open:

| Document state | Notification | Version |
| --- | --- | --- |
| Open through a previous lookup or Write | `textDocument/didChange` | Previous version plus one |
| Not yet open | `textDocument/didOpen`, including its mapped language ID | 1 |

Versions are independent for each URI and advance only after a successful
notification. Navigation and Write must agree on the document's URI, open state,
and current version across agent-loop iterations. Reading a file with Read, or
receiving its location in an LSP result, doesn't open it in the language server.

The save must succeed before notification, and synchronization must complete
before Write returns its tool result. Subsequent lookups on the same connection
must use the new contents.

### Synchronize a Write to an open document

If `checkout.py` is open at version 1, changing its import to `discounts` requires
this [didChange notification][did-change]:

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

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
