In this stage, Write will return diagnostics so the agent can repair an edit.

### The repair we're working toward

Pricing now returns a `Price` object with a `cents` field. Checkout stores it in
`amount`, then incorrectly returns it from a function annotated to return int.
The repair is `return amount["cents"]`.

The tester supplies this incomplete edit. Its model requests repair only after
Write returns the diagnostic.

### Collect fresh feedback after each Write

Keep a notification cursor, initially `0`, for the supplied connection. Follow
these steps for each Write:

1. **Before saving**, drain queued messages by calling
   `client.call("notifications", {"after": cursor, "timeoutMs": 0})`.
   Save the returned `cursor` so earlier messages cannot count as this edit's
   feedback.
2. **Save and synchronize.** After a successful save, send didChange as in the
   previous stage. If the file isn't open, send didOpen with its new contents.
   If saving fails, return the existing Write error.
3. **Wait for feedback.** Call the same notifications action with
   `{"after": cursor, "timeoutMs": 1000}`. Advance the cursor after every batch,
   including batches about other files. Repeat up to an overall deadline, for
   example three seconds.
4. **Select a fresh publication.** Look for `textDocument/publishDiagnostics`
   for the written URI. Discard reports whose version is older than the current
   document. Accept unversioned reports in arrival order. Replace that URI's
   previous diagnostic list, including when the new list is empty.
5. **Return the result.** Include the selected diagnostics in this Write's tool
   result and continue the agent loop. On timeout, return a feedback error.
   An empty notification batch is not a clean diagnostic report.

A notifications response can look like this:

```json
{
  "cursor": 8,
  "notifications": [
    {
      "method": "textDocument/publishDiagnostics",
      "params": {
        "uri": "file:///project/checkout.py",
        "version": 2,
        "diagnostics": [
          {
            "range": {
              "start": { "line": 5, "character": 11 },
              "end": { "line": 5, "character": 17 }
            },
            "severity": 1,
            "message": "Type Price is not assignable to return type int"
          }
        ]
      }
    }
  ]
}
```

### Return feedback to the model

An example Write result:

```json
{
  "written": "/project/checkout.py",
  "uri": "file:///project/checkout.py",
  "diagnostics": [
    {
      "range": {
        "start": { "line": 5, "character": 11 },
        "end": { "line": 5, "character": 17 }
      },
      "severity": 1,
      "message": "Type Price is not assignable to return type int"
    }
  ]
}
```

Keep LSP read-only; diagnostics belong in Write's result. Serialize this value
as JSON in the tool message's `content`, with the matching `tool_call_id`.
After repair, a fresh empty publication produces:

```json
{
  "written": "/project/checkout.py",
  "uri": "file:///project/checkout.py",
  "diagnostics": []
}
```

### Tests

Cases cover repair, clearing, unversioned reports, stale versions, and missing
feedback. The fixture publishes once per open/change; real servers control timing.
Unversioned reports cannot prove which edit was analyzed. Cleared diagnostics
establish that reported errors are gone; project tests check behavior.
