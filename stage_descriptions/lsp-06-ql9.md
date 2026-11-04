In Stage 5, your agent sent edits to the language server. Now you'll return the
server's diagnostic feedback to the model so it can repair errors introduced by
those edits.

A diagnostic describes an issue in a file, with a message, severity, and source
range. For example, changing a function to return a dictionary can make a caller's
`int` return annotation incorrect. Definition lookup still finds the function;
diagnostics explain what needs fixing.

### Change the API and repair its callers

The tester supplies the same Python invoice project. The task is to change
`pricing.total` from returning integer cents to returning a `Price` TypedDict:

```python
from typing import TypedDict


class Price(TypedDict):
    cents: int


def total(price: int, quantity: int) -> Price:
    return {"cents": price * quantity}
```

Both callers must extract the `cents` field. Checkout must still return integer
`500`, reporting must return integer `600`, and the unrelated `preview.total`
must keep its behavior. The model uses definition lookup, references, and Read
to inspect the implementation and its callers, then Write to edit them.

An incomplete checkout edit might look like this:

```python
def checkout_total() -> int:
    amount = invoice_total(250, 2)
    return amount
```

After the API change, `amount` is a `Price`, while this function promises an
`int`. The language server can report that mismatch. Returning
`amount["cents"]` repairs it. Your new work is to deliver the error and the
subsequent clean report through Write's existing tool-result flow.

### Read the server's feedback

The server sends diagnostics asynchronously in `textDocument/publishDiagnostics`
notifications. They are not the response to `didChange`. The supplied helper
queues them while your agent executes other calls.

Keep a notification cursor beside the client and Stage 5's document-version map.
Initialize it to `0`. Call the client's `call` method with action `notifications`
and this payload, using the same language-specific call pattern as earlier stages:

```json
{ "after": 0, "timeoutMs": 0 }
```

Use your saved cursor as `after`. A zero timeout drains queued messages without
waiting. The response contains a new cursor and a notification array:

```json
{
  "cursor": 4,
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

Save every returned cursor, including when the batch is empty or contains only
unrelated messages. Diagnostic ranges are zero-based, like navigation results.

### Add feedback to Write

For each successful Write to a supported Python file:

1. **Drain old notifications before the edit.** Advance the cursor so a queued
   report from an earlier edit cannot satisfy this Write.
2. **Save and synchronize.** Keep Stage 5's save, `didOpen` or `didChange`, and
   per-URI version tracking. Finish synchronization before collecting feedback.
3. **Wait for the written file's report.** Poll `notifications` after the saved
   cursor with a short timeout, such as `200` milliseconds. Use an overall
   deadline, such as two seconds; each empty batch must not restart that deadline.
4. **Select current feedback.** Consider only `textDocument/publishDiagnostics`
   for the written file's URI. If a version is supplied, it must match the version
   just synchronized. Accept unversioned reports received after the pre-edit
   drain. Choose the latest matching report in each batch. Ignore other methods,
   other files, and older versions.
5. **Return the result to the model.** Preserve your Write success information
   and add the selected report's complete `params` object under `diagnostics`.
   Wait for this collection to finish before returning the tool result. Use
   `await` with asynchronous clients.

For example, after the repair, Write's result could contain:

```json
{
  "written": "/project/checkout.py",
  "diagnostics": {
    "uri": "file:///project/checkout.py",
    "version": 3,
    "diagnostics": []
  }
}
```

Your existing success fields may differ; the new `diagnostics` field contains
the server's report. Preserve its URI, optional version, and complete diagnostic
array. An empty diagnostic array clears the previous errors for that file.
An empty notification batch means no report arrived yet; it does not mean the
file is error-free.

If the overall deadline expires, keep the successful Write result and add
`diagnosticsError` with a message such as
`"Timed out waiting for language-server diagnostics"`. Omit `diagnostics` in
that result. The save succeeded, but analysis is unavailable. Do not invent a
clean report or turn the successful save into a file-write failure.

Add this guidance to the system prompt:

```text
Inspect diagnostic feedback from Write and repair reported type errors.
A diagnostic timeout means feedback is unavailable, not that the file is clean.
```

### Complete the migration

The tester gives your agent this task:

```text
Change pricing.total to return a Price TypedDict with an integer cents field.
Update checkout.py and reports.py so their results stay unchanged.

Use LSP to find the implementation and callers, and recheck them after editing.
Use Write's diagnostic feedback to fix type errors. Report any diagnostic timeout.

Leave tests and unrelated files unchanged.
Run python3 -m unittest -v test_invoice.py and report the result.
```

The model chooses edits in normal use. For consistent grading, the tester
supplies a sequence that includes an incomplete caller edit and its repair.
You do not need to deliberately introduce errors in your agent's implementation.
Execute each tool call, collect its real feedback, and return it with the matching
`tool_call_id` before continuing the loop.

Diagnostics and project tests serve different purposes. Diagnostics locate type
errors; the five supplied Python tests check the new API and preserved behavior.
Return the actual Bash output, leave the tests unchanged, and use the updated
function's position for follow-up references.

### Tests

Run `codecrafters test`. Stage 6 checks that the caller's type error reaches the
model in the incomplete Write's result, and that the repair's result contains a
new, empty report. It also checks stale and unrelated notifications, reports
without versions, and an explicit timeout when the server publishes no report.
Existing migration, current-navigation, unchanged-file, and Bash-output checks
remain in place.

A Stage 5 agent that only synchronizes edits will fail this stage until it
returns diagnostic feedback.

