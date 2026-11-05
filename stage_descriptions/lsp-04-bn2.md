In this stage, you'll synchronize `Write` edits so definition and reference
lookups use the updated code.

### Why is the answer still pointing to the old file?

Suppose definition lookup on checkout's `invoice_total` call points to
`pricing.total`. The model then changes the import from `pricing` to `discounts`,
keeping the alias and call unchanged. The same lookup should now point to
`discounts.total`.

Saving updates the file on disk. The language server also needs its new contents
through the existing client. Otherwise, it keeps answering from the old code.

Add this guidance to your system prompt:

```text
Edit files with Write so the language server sees changes.
```

### Track each document's state

Replace the set of opened URIs from definition lookup with a map from URI to document version.
Keep this map beside the client, outside the agent loop, and share it between
navigation and Write. A URI in the map is open, and a URI absent from it is closed.
Reuse navigation's path resolution and URI builder in Write so both handlers
find the same record.

Whenever either handler successfully sends `didOpen`, record version 1.
Each URI has its own version counter. Reading a file with Read, or receiving
its location in an LSP result, doesn't open it in the language server.

### Add synchronization to Write

For a Write to a file supported by the client's language mapping (`.py` maps to
`python` in the [invoice project][example]):

1. Save the file using your existing Write handler.
2. After the save succeeds, send its complete new contents through `notify`.
   For an open URI, send `didChange` with its recorded version plus one.
   For a closed URI, reuse the `didOpen` payload from definition lookup with its URI, mapped
   language ID, version 1, and complete new contents.
3. Wait for the notification call to complete, record the sent version in the
   shared map, then return Write's tool result. In JavaScript, TypeScript, and
   C#, `await` the `notify` call before returning.

Finish synchronization before the model's next lookup on the same connection.

### Synchronize a Write to an open document

If `checkout.py` is open at version 1, changing its import to `discounts` requires
this [`didChange` notification][did-change]. After saving, send it through `notify`
using your language's client-call pattern from definition lookup:

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

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Use Write to change its import from pricing to discounts, preserving the invoice_total alias. Repeat definition lookup at the same position and report the new target."
<the model's report that the definition moved to discounts.total>
```

The tester will verify that:

- The first lookup's tool result points to `pricing.py`, and the lookup after the Write points to `discounts.py`
- `checkout.py` on disk imports from `discounts`
- The server's copy of every open document matches the file on disk
- Your program exits with code `0`

The tester will also run a prompt that restores the `pricing` import and looks up the definition a third time, which needs version 3. Another prompt writes `checkout.py` before any lookup, so the Write has to send `didOpen`.

### Notes

- Every test case uses a successful Write to a supported Python file. Failed writes and files outside the language mapping are out of scope.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
