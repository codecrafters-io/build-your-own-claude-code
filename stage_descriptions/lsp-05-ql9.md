In this stage, you'll return language-server diagnostics to the model so it can repair an API migration.

### Why diagnostics?

Your agent already sends each Write to the language server. The server can also
report problems in what was written. A diagnostic describes an issue in a file,
with a message, severity, and source range. For example, changing a function to
return a dictionary can make a caller's `int` return annotation incorrect.
Definition lookup still finds the function, and diagnostics explain what needs
fixing.

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

Keep a notification cursor beside the client and the document-version map.
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
2. **Save and synchronize.** Keep the save, `didOpen` or `didChange`, and
   per-URI version tracking. Finish synchronization before collecting feedback.
3. **Wait for the written file's report.** Poll `notifications` after the saved
   cursor with a short timeout, such as `200` milliseconds. Use an overall
   deadline, such as two seconds. An empty batch must not restart that deadline.
4. **Select current feedback.** Consider only `textDocument/publishDiagnostics`
   for the written file's URI. If a version is supplied, it must match the version
   just synchronized. Accept unversioned reports received after the pre-edit
   drain. Choose the latest matching report in each batch. Ignore other methods,
   other files, and older versions.
5. **Return the result to the model.** Preserve your Write success information
   and add the selected report's complete `params` object under `diagnostics`.
   Wait for this collection to finish before returning the tool result. In
   JavaScript, TypeScript, and C#, `await` each `notifications` call.

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

Your existing success fields may differ. The new `diagnostics` field contains
the server's report. Preserve its URI, optional version, and complete diagnostic
array. An empty diagnostic array clears the previous errors for that file.
An empty notification batch means no report arrived yet. It does not mean the
file is error-free.

If the overall deadline expires, keep the successful Write result and add
`diagnosticsError` with a message that contains both "timed out" and
"diagnostic", such as `"Timed out waiting for language-server diagnostics"`. Omit `diagnostics` in
that result. The save succeeded, but analysis is unavailable. Do not invent a
clean report or turn the successful save into a file-write failure.

Add this guidance to the system prompt:

```text
Inspect diagnostic feedback from Write and repair reported type errors.
A diagnostic timeout means feedback is unavailable, not that the file is clean.
```

### Complete the migration

The tester's prompt asks the model to work in this order:

1. Look up the definition of `invoice_total` in `checkout.py`, then find the references of the `pricing.total` it returns.
2. Read `pricing.py`, `checkout.py`, and `reports.py`, then Write the migration, fixing any type errors the diagnostics report.
3. Repeat both lookups at the current positions. The definition now sits below the `Price` class, so the model converts the returned zero-based range to one-based tool inputs.
4. Run `python3 -m unittest -v test_invoice.py` with Bash.

Execute each tool call, collect its real feedback, and return it with the matching
`tool_call_id` before continuing the loop. Either lookup order is accepted within
each phase. An edit can move the checkout call to a different line or column, so
locate it in the updated source before the follow-up definition lookup.

Diagnostics and project tests serve different purposes. Diagnostics locate type
errors, and the five supplied Python tests check the new API and preserved behavior.

### Tests

The tester will create the invoice project with `test_invoice.py` and execute your program like this:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with an integer cents field. Update checkout.py and reports.py so their results stay unchanged. Before any Write edits, use LSP goToDefinition on checkout.py at line 5, character 12, and LSP findReferences on the returned pricing.total definition. After all Write edits, repeat LSP goToDefinition on the invoice_total call in checkout.py at its current line and character, and LSP findReferences at the updated pricing.total definition. Use the returned definition position for findReferences, converting its zero-based range to one-based tool inputs. Both post-edit LSP queries are required even if diagnostics are clean and the project tests pass. Use diagnostic feedback from Write to fix type errors. Report any diagnostic timeout. Leave tests and unrelated files unchanged. Run python3 -m unittest -v test_invoice.py and report the result."
<the model's summary of the migration and the test result>
```

The tester will verify that:

- Every Write's tool result is a JSON object whose `diagnostics` field holds the server's report for the version that Write synchronized
- Both lookups run before the first Write and again after the last Write, and the follow-up references match the edited files
- The model reads `pricing.py`, `checkout.py`, and `reports.py` before writing each one
- The Bash output shows `Ran 5 tests` and `OK`, `checkout_total()` returns `500`, and `report_total()` returns `600`
- `preview.py` and `test_invoice.py` are unchanged
- Your program exits with code `0`

The tester will also run this prompt against servers that send a stale report before the current one, that omit `version` from reports, and that never publish a report. In that last case, every Write must return `diagnosticsError`. Another case adds a comment line above `def total` in `pricing.py`, so the definition is not on line 1.

### Notes

- If your Write handler returns plain text such as `Wrote checkout.py`, change it to return a JSON object, so the `diagnostics` field has somewhere to go.
- The model chooses its own edits, so a run may or may not hit a type error. You don't need to introduce errors yourself. Each Write only has to return the report the server published for it, which is often an empty `diagnostics` array.
- An agent that synchronizes edits but doesn't return diagnostics fails this stage.

