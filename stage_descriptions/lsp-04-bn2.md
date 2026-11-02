In this stage, you'll keep language-server answers current after your agent edits.

### Why is the answer still pointing to the old file?

Your agent changes checkout's import from `pricing` to `discounts`, preserving
the local name `invoice_total`. The file on disk is correct, but definition
lookup still points to pricing: the server has its own copy from didOpen.

Send the edit to that same server and repeat the query. It should now point to
`discounts.total`. In the final stage, the same synchronization keeps analysis
current while your agent updates several files.

### Extend your Write handler

After a successful write to an open document, send a
[didChange notification][did-change]:

1. Increment that URI's document version.
2. Pass the complete object below to `client.call("notify", payload)`.
3. Continue the existing agent loop.

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
need to calculate a diff. Keep a separate version counter for each URI:
`didOpen` uses version 1, followed by 2, 3, and so on.

For a file that isn't open, your later navigation handler can send didOpen with
its current contents. Don't send a change if writing to disk failed. Keep using
the supplied connection throughout the run.

### Tests

The tester requests a definition lookup, changes the import with Write, and
requests the same lookup again. The targets must change from pricing to
discounts. Another case restores the import and expects pricing again.

It also checks writing before the first lookup and a failed write to a
directory. Every successful open-document edit must reach the server, and failed
writes must leave its analysis unchanged.

The test output shows the updated target. Restarting the server or returning
the old location doesn't satisfy synchronization.

[did-change]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didChange
