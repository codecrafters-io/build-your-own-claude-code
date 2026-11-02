In this stage, you'll return diagnostic feedback after Write so your existing
agent loop can repair a caller missed during an API change.

### Replay the opening failure

Pricing now returns a `Price` object with a `cents` field. A partial checkout
migration stores that object in `amount`, then returns it from a function
annotated to return int. The file saves successfully, but the code has a type
error. The repair is `return amount["cents"]`.

The tester fixes this first attempt so the before/after comparison is repeatable.
It requests the repair only after the preceding Write result contains the error.

### Add feedback to Write

Diagnostics arrive as `textDocument/publishDiagnostics` notifications:

```json
{
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
```

Use the supplied helper's notifications action. Its cursor tracks messages even
while requests are running; the helper guide includes the call shape.

Before an edit, drain pending notifications and record the cursor. After saving,
send didChange, or didOpen with the new text if unopened. Wait for a new
publication for that file and include its diagnostics in this Write's result.
Replace each URI's previous list; an empty publication clears it.

Discard versioned reports older than your current document. Accept unversioned
reports in arrival order. Use a bounded wait; missing feedback is an explicit
error, not an empty success list. Unversioned reports cannot prove which edit
was analyzed. The fixture publishes once per open/change; real servers control
their own timing.

### Tests

The tester migrates pricing and reporting, then replays the incomplete checkout
edit. Write must deliver its error, followed by an empty list after repair.
Cases also cover unversioned, stale, and missing publications.

The output shows saved file, type error, repair, and clearing. Keep LSP read-only:
feedback belongs in the existing Write result. Tests still check behavior;
cleared diagnostics only establish that the reported errors are gone.
