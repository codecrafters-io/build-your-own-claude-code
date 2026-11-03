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

Keep this guidance in your system prompt:

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

Extend the opened-document tracking from Stage 3 to store a version for each
URI. `didOpen` starts at version 1. Each later change to that document uses a
higher version: 2, then 3, and so on. The version identifies which revision of
the document you're sending.

Track versions per URI, rather than using one counter for the whole project.
For example, checkout can be at version 3 while pricing is still at version 1.
Reuse navigation's path resolution and URI builder so writing a file finds the
same document record as looking it up.

### Synchronize a Write to an open document

Suppose you've already sent `didOpen` with version 1 for this `checkout.py`:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

The model requests this Write, changing only the module it imports from:

```json
{"file_path":"checkout.py","content":"from discounts import total as invoice_total\n\n\ndef checkout_total() -> int:\n    return invoice_total(250, 2)\n"}
```

After a successful write to an open document, send a
[didChange notification][did-change]:

1. Increment that URI's document version. Here, version 1 becomes version 2.
2. Send the helper action `notify` with the complete object below, using your
   language's client-call pattern from Stage 3. The LSP method is
   `textDocument/didChange`.
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

The course server uses full synchronization: each change notification supplies
the entire new file. That's why `contentChanges` contains one object with the
complete `text` and no range describing a smaller edit. Use the contents that
were successfully written, including their line breaks; you don't need to
calculate a diff.

Waiting for the client call to complete keeps the change notification ahead of
the model's next lookup. Keep using the same URI and connection. For another
successful Write to this open document, send `didChange` with version 3 instead
of sending `didOpen` again.

### Synchronize a Write to a closed document

A supported file may not be in your open-document record yet. For example, a
references request on `pricing.py` can discover uses in `reports.py` without your
agent opening `reports.py` in the server.

After a successful Write to such a file, send `didOpen` with its URI, mapped
language ID, complete new contents, and version 1, using Stage 3's payload. Once
that call succeeds, record the URI as open at version 1. Later writes to it use
`didChange` with increasing versions. Wait for the notification call to complete
before returning Write's result here too.

This matters because a server may have already indexed the file while analyzing
imports and references. Sending its new contents refreshes that view even if the
next query targets a different file. Waiting until the model queries the edited
file itself could leave answers about other files based on the old code.

A supported file has an extension in the mapping you saved in Stage 1. Files
with other extensions continue to use ordinary Write without LSP notifications.

### Handle failures in the right order

Save the file before notifying the server. If the write fails, return the Write
error without sending a notification or advancing the document's version.
Otherwise, the server could analyze contents that were never saved.

If the save succeeds but synchronization fails, report that synchronization
failure in Write's tool result. The file has changed on disk, but you can't claim
the server's view was updated. Preserve the helper's error message so the model
can see what went wrong. Completing a notification call sends the update; it
doesn't tell you whether the edited program is correct. You'll check program
behavior with tests in the final stage.

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

The call's position and alias are unchanged. Only the import changed, so the new
target shows that the server received and used the edited contents. Returning
`pricing.py` again would show that the lookup still used the old document.

Substitute the actual project URI. Other cases restore the import, write before
lookup, and attempt a directory write. Failed writes must leave analysis unchanged.
These exercise repeated versions, opening a file after Write, and keeping failed
edits out of the server's view. The final explanation can vary.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
