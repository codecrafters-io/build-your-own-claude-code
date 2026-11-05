In this stage, you'll synchronize `Write` edits so definition and reference
lookups use the updated code.

### Why is the answer still pointing to the old file?

Suppose the model changes `checkout.py`'s import from `pricing` to `discounts`,
keeping the `invoice_total` alias. A definition lookup on `invoice_total` should
now point to `discounts.total` instead of `pricing.total`.

Your Write tool saves the new text to disk, but the language server still has
the copy you sent with `didOpen`, and keeps answering from it. To keep its
answers current, send it every change your Write tool makes.

### Track each document's state

Replace the set of opened URIs from definition lookup with a map from URI to document version.
Keep one map for the whole run, not one tool call, and share it between
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
2. After the save succeeds, send its complete new contents with `call` and
   `"notify"`. For an open URI, send `didChange` with its recorded version plus
   one. For a closed URI, send `didOpen` with version 1 and the new contents. The
   server may already hold the old file from disk, for example to answer
   references, and `didOpen` replaces it.
3. Wait for the notification call to complete, record the sent version in the
   shared map, then return Write's tool result. In JavaScript, TypeScript, and
   C#, `await` the `notify` call before returning.

For example, if `checkout.py` is open at version 1, changing its import to
`discounts` sends this [`didChange` notification][did-change]:

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
is needed.

The version tells the server which copy is newest, so each change must use a
higher number than the last. The next Write to `checkout.py` sends version 3.

### Tell the model to edit with Write

Add this guidance to your system prompt, so the model doesn't edit files with
Bash (for example, `sed`), which would skip synchronization:

```text
Edit files with Write so the language server sees changes.
```

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Use Write to change its import from pricing to discounts, preserving the invoice_total alias. Repeat definition lookup at the same position and report the new target. Restore the pricing import using Write and repeat the definition lookup."
<the model's report of the three definition targets>
```

When your program passes, the tester prints:

```text
[tester::#BN2] Definition lookup followed the updated import without restarting the server
[tester::#BN2] Case successive-document-versions passed protocol, tool-result and file checks
```

The tester will verify that:

- The three lookups' tool results point to `pricing.py`, then `discounts.py`, then `pricing.py` again
- Each Write sends `checkout.py` with a higher version than the last
- `checkout.py` on disk ends with the `pricing` import
- The server's copy of every open document matches the file on disk
- Your program exits with code `0`

The tester will also run a prompt that writes `checkout.py` before any lookup, so the Write has to send `didOpen`.

### Notes

- Every test case uses a successful Write to a supported Python file. We won't deal with failed writes or files outside the language mapping in this extension.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
