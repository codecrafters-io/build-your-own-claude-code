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

The client's `notifications` action retrieves queued messages after a cursor.
The initial cursor is `0`:

```json
{ "after": 0, "timeoutMs": 0 }
```

`after` is the last cursor you received. `timeoutMs` controls how long the call
waits for new messages; zero drains queued messages without waiting. The response
contains a new cursor and a notification array:

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

Each subsequent call uses the returned cursor, including after an empty batch
or one containing only unrelated messages. Diagnostic ranges are zero-based,
like navigation results.

### Add feedback to Write

Each successful Write to a supported Python file must return its current
diagnostic report along with the existing success information. Synchronization
from the previous stage must finish before feedback is collected, and feedback
collection must finish before the tool result reaches the model.

A current report is a `textDocument/publishDiagnostics` notification for the
written file's URI. If it includes a version, that version must match the one
just synchronized. Unversioned reports are accepted when received after old
notifications have been drained before the edit. Queued reports from earlier
edits cannot satisfy the current Write. When a batch contains several matching
reports, the latest one takes precedence.

The wait must have a finite overall deadline, even if batches are empty or
contain only unrelated messages. Return the selected report's complete `params`
object under `diagnostics`, preserving its URI, optional version, and diagnostic
array.

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

Your existing success fields may differ. An empty diagnostic array clears the
previous errors for that file.
An empty notification batch means no report arrived yet; it does not mean the
file is error-free.

If the overall deadline expires, keep the successful Write result and add
`diagnosticsError` with a message such as
`"Timed out waiting for language-server diagnostics"`. Omit `diagnostics` in
that result. The save succeeded, but analysis is unavailable. Do not invent a
clean report or turn the successful save into a file-write failure.

Your system prompt should explain how to use the feedback, for example:

```text
Inspect diagnostic feedback from Write and repair reported type errors.
A diagnostic timeout means feedback is unavailable, not that the file is clean.
```

### Complete the migration

The tester asks the model to migrate `pricing.total` and its callers, use LSP
navigation and diagnostic feedback, and run `python3 -m unittest -v test_invoice.py`.
The completed migration must preserve caller behavior and leave tests and
unrelated files unchanged.

The live model chooses its tool calls and edits during grading. Your agent
executes those calls and returns real feedback with the matching `tool_call_id`.
Keep your handlers general so they execute whichever edits the model requests.
There is no need to deliberately introduce errors to demonstrate a repair.

Edits can move symbols to different lines or columns. Any subsequent LSP request
must use the current source position, with the usual conversion between
zero-based returned ranges and one-based tool inputs.

Diagnostics and project tests serve different purposes. Diagnostics locate type
errors; the five supplied Python tests check the new API and preserved behavior.

### Tests

Run `codecrafters test`. Stage 6 checks that every successful Write returns the
current diagnostic report, including a new, empty report when an edit clears
earlier errors. It also checks stale and unrelated notifications, reports without
versions, and an explicit timeout when the server publishes no report.
It also verifies the migration and navigation requirements in the task above,
that unrelated files remain unchanged, and that the model receives the actual
Bash output.
