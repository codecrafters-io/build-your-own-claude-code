In this stage, you'll synchronize `Write` edits to keep language-server answers current.
Your agent can now find implementations and references. Next, you'll make sure
those lookups use the new code after the model edits a file.

### Why is the answer still pointing to the old file?

Suppose the model uses definition lookup on checkout's `invoice_total` call and
gets a location in `pricing.py`. It then changes the import from `pricing` to
`discounts`, keeping the alias and call unchanged. The next lookup at the same
position should point to `discounts.total`.

But saving the file updates only the copy on disk. For an open document, the
language server still has the contents your agent sent through `didOpen`, or its
most recent change notification. Without an update, it can keep answering as
though checkout still imports from `pricing`.

**A successful file write and an up-to-date server view are two separate steps.**
Your Write handler will connect them: first save the file, then send its new
contents through the existing client. Keeping the same server connection lets
later definition and reference requests use the updated document.

Add this guidance to your system prompt:

```text
Edit files with Write so the language server sees changes.
```

You'll add synchronization to the Write handler. Bash edits don't pass through
that handler, and the helper doesn't watch those edits for you. Asking the model
to use Write ensures its edits take the path you're about to implement.

### Track each document's state

An **open document** is a URI you've successfully sent with `didOpen`.
Reading a file with Read, or receiving its location in an LSP result, doesn't
open it in the language server.

Replace Stage 3's set of opened URIs with a map from URI to document version.
Keep this map beside the client, outside the agent loop, and share it between
navigation and Write. A URI in the map is open; a URI absent from it is closed.

Whenever either handler successfully sends `didOpen`, record version 1 for
that URI. Update navigation to use this map in place of the old set. Later
changes use increasing versions: 2, then 3, and so on. The version identifies
which revision of the document you're sending.

Track versions per URI, rather than using one counter for the whole project.
For example, checkout can be at version 3 while pricing is still at version 1.
Reuse navigation's path resolution and URI builder so writing a file finds the
same document record as looking it up.

### Add synchronization to Write

A supported file has an extension in the client's language mapping from Stage 3.
The exercise edits Python files, whose `.py` extension maps to `python`.

For a Write to a supported file:

1. Save the file using your existing Write handler.
2. After the save succeeds, send its complete new contents through `notify`.
   For an open URI, send `didChange` with its recorded version plus one.
   For a closed URI, send `didOpen` with version 1.
3. Wait for the notification call to complete, record the sent version in the
   shared map, then return Write's tool result. Use `await` with asynchronous
   clients.

This order keeps the update ahead of the model's next lookup on the same
connection.

### Synchronize a Write to an open document

Suppose `checkout.py` is open at version 1. The model uses Write to replace
`from pricing import total as invoice_total` with:

```python
from discounts import total as invoice_total
```

The rest of the file stays the same. After saving, send this
[didChange notification][did-change] through `notify`, using your language's
client-call pattern from Stage 3. Version 1 becomes version 2:

```json
{
  "method": "textDocument/didChange",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py", "version": 2 },
    "contentChanges": [{ "text": "from discounts import total as invoice_total\n\n\ndef checkout_total() -> int:\n    return invoice_total(250, 2)\n" }]
  }
}
```

The course server uses full synchronization: each change notification supplies
the entire new file. That's why `contentChanges` contains one object with the
complete `text` and no range describing a smaller edit. Use the contents that
were successfully written, including their line breaks; you don't need to
calculate a diff.

For another successful Write to this open document, send `didChange` with
version 3.

### Synchronize a Write to a closed document

A supported file may not be in your open-document record yet. For example, a
references request on `pricing.py` can discover uses in `reports.py` without your
agent opening `reports.py` in the server.

After a successful Write to such a file, send `didOpen` with its URI, mapped
language ID, complete new contents, and version 1, using Stage 3's payload.
Recording version 1 in the shared map lets later lookups skip `didOpen` and
later writes use `didChange`.

This matters because a server may have already indexed the file while analyzing
imports and references. Sending its new contents refreshes that view even if the
next query targets a different file. Waiting until the model queries the edited
file itself could leave answers about other files based on the old code.

### Tests

The tester writes the invoice project and runs:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Use Write to change its import from pricing to discounts, preserving the invoice_total alias. Repeat definition lookup at the same position and report the new target."
```

The tester checks that definition lookup changes from `pricing.total` to
`discounts.total` after Write. The call's position and alias stay the same,
so the new target shows that the server used the edited contents. Return each
server location through your existing tool-result flow.

Additional cases check repeated versions and Write before the first lookup.
All cases use successful writes to supported Python files.

Your agent now keeps navigation results current after Write edits.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
