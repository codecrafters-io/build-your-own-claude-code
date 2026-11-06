In this stage, you'll synchronize `Write` edits so definition and reference
lookups use the updated code.

### Why synchronize edits?

After the model changes checkout's import from `pricing` to `discounts`, a
lookup on `invoice_total` should find `discounts.total`. Saving the file updates
the disk, but the language server still holds the text sent with `didOpen`.
Synchronizing Write edits keeps its answers consistent with the saved code.

### Expected behavior

Every successful Write to a supported file must synchronize the complete saved
text before returning its tool result. Subsequent definition and reference
lookups must reflect the edits. The client's language mapping identifies
supported files (`.py` maps to `python` in the [invoice project][example]).

The notification depends on the document's state on the current connection:

| Document state | Notification | Version |
| --- | --- | --- |
| Already open through navigation or Write | `textDocument/didChange` | Previous version plus one |
| Not yet open | `textDocument/didOpen`, including its mapped language ID | 1 |

Navigation and Write must agree on the URI, open state, and current version of
each document throughout the run. The save must succeed before the notification,
and the recorded version advances only after that notification succeeds.

### Full document updates

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

The model should use Write for edits so they reach the language server.

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Use Write to change its import from pricing to discounts, preserving the invoice_total alias. Repeat definition lookup at the same position and report the new target. Restore the pricing import using Write and repeat the definition lookup."
<the model's report of the three definition targets>
```

The tester will verify that:

- The three lookups' tool results point to `pricing.py`, then `discounts.py`, then `pricing.py` again
- Each Write sends `checkout.py` with a higher version than the last
- `checkout.py` on disk ends with the `pricing` import
- The server's copy of every open document matches the file on disk
- Your program exits with code `0`

The tester will also run a prompt that writes `checkout.py` before any lookup, so the Write has to send `didOpen`.

### Notes

- Read and returned reference locations don't open documents in the language server. A Write to an indexed but closed file still needs `didOpen` with the new contents.
- JavaScript, TypeScript, and C# clients are asynchronous; await the notification before returning Write's result.
- The protocol defines the [didChange notification][did-change].
- Every test case uses a successful Write to a supported Python file. We won't deal with failed writes or files outside the language mapping in this extension.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
