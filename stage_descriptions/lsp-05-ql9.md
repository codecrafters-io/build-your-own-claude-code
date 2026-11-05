In this stage, you'll return language-server diagnostics to the model so it can repair an API migration.

### Why diagnostics?

Your agent already sends each Write to the language server. The server can also
report problems in what was written. A diagnostic describes an issue in a file,
with a message, severity, and source range.

### Change the API and repair its callers

In this example, the model migrates the [invoice project][example] using your
agent's tools. It changes `pricing.total` from returning integer cents, such as
`500`, to returning a `Price`, a dictionary with a `cents` key such as
`{"cents": 500}`:

```python
from typing import TypedDict


class Price(TypedDict):
    cents: int


def total(price: int, quantity: int) -> Price:
    return {"cents": price * quantity}
```

The callers in `checkout.py` and `reports.py` have to read the `cents` field to
keep their results unchanged: `checkout_total()` must still return the integer
`500`, and `report_total()` the integer `600`. The unrelated `preview.total`
stays as it is.

Part-way through, the model might edit `checkout.py` like this:

```python
def checkout_total() -> int:
    amount = invoice_total(250, 2)
    return amount
```

After the API change, `amount` is a `Price`, while this function is declared to
return an `int`. The language server can report that mismatch, and your Write
tool passes it back so the model can fix it by returning `amount["cents"]`.

### Read the server's feedback

The server sends diagnostics asynchronously in `textDocument/publishDiagnostics`
notifications. They are not the response to `didChange`. Your LSP client
queues them while your agent executes other calls.

Keep a notification cursor for the whole run, like the document-version map,
and initialize it to `0`. Read queued notifications with `call` and
`"notifications"`, passing this payload:

```json
{ "after": 0, "timeoutMs": 0 }
```

Use your saved cursor as `after`. It counts the notifications you've already
read, so the response holds only newer ones, plus a new `cursor` to pass next
time. A zero timeout drains queued messages without waiting. For the incomplete
edit above, the response contains:

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

After each save, your Write tool waits for the server's report on that file and
returns it to the model with the write result. For each successful Write to a
file your LSP client's language mapping covers:

1. **Drain old notifications.** Read notifications with a zero timeout and save
   the cursor, so a report from an earlier edit can't answer this one.
2. **Save and synchronize** as your Write tool already does: the save, then
   `didOpen` or `didChange` with the next version.
3. **Wait for the report.** Poll notifications with a short timeout, such as
   `200` milliseconds, within an overall deadline, such as two seconds. An empty
   batch means no report has arrived yet, not that the file is clean, and it
   doesn't restart the deadline.
4. **Pick the current report.** Use only `textDocument/publishDiagnostics` for
   the written file's URI whose `version` matches the version you just sent, or
   that has no `version`. If a batch has several, use the latest.
5. **Return it.** Keep your Write success information and add the report's
   complete `params` object under `diagnostics`. In JavaScript, TypeScript, and
   C#, `await` each `notifications` call.

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

Your existing success fields may differ. An empty `diagnostics` array means the
server found no errors, and it clears the earlier ones for that file.

If the overall deadline expires, keep the successful Write result and add
`diagnosticsError` with a message that contains both "timed out" and
"diagnostic", in any letter case, such as
`"Timed out waiting for language-server diagnostics"`.
Omit `diagnostics` in that result. The save succeeded, but analysis is
unavailable. Do not invent a clean report or turn the successful save into a
file-write failure.

### Tell the model to use the feedback

Add these lines to your system prompt, alongside the LSP guidance it already has:

```text
Inspect diagnostic feedback from Write and repair reported type errors.
A diagnostic timeout means feedback is unavailable, not that the file is clean.
```

### Tests

The tester will create the [invoice project][example] with `test_invoice.py` and execute your program like this:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with an integer cents field. Update checkout.py and reports.py so their results stay unchanged. Before any Write edits, use LSP goToDefinition on checkout.py at line 5, character 12, and LSP findReferences on the returned pricing.total definition. After all Write edits, repeat LSP goToDefinition on the invoice_total call in checkout.py at its current line and character, and LSP findReferences at the updated pricing.total definition. Use the returned definition position for findReferences, converting its zero-based range to one-based tool inputs. Both post-edit LSP queries are required even if diagnostics are clean and the project tests pass. Use diagnostic feedback from Write to fix type errors. Report any diagnostic timeout. Leave tests and unrelated files unchanged. Run python3 -m unittest -v test_invoice.py and report the result."
<the model's summary of the migration and the test result>
```

The tester will verify that:

- Every Write's tool result is a JSON object whose `diagnostics` field holds the server's report for the version that Write synchronized
- Both lookups run, in either order, before the first Write and again after the last Write, and the follow-up references match the edited files
- The model reads `pricing.py`, `checkout.py`, and `reports.py` before writing each one
- The Bash output shows `Ran 5 tests` and `OK`, `checkout_total()` returns `500`, and `report_total()` returns `600`
- `preview.py` and `test_invoice.py` are unchanged
- Your program exits with code `0`

The tester will also run this prompt against two other servers. One sends stale reports around a current report that has no `version`. The other never publishes a report, and its `pricing.py` has a comment line above `def total`, so the definition is not on line 1. In that case, every Write must return `diagnosticsError`.

### Notes

- If your Write tool returns plain text such as `Wrote checkout.py`, change it to return a JSON object, so the `diagnostics` field has somewhere to go.
- The model chooses its own edits, so a run may or may not hit a type error. You don't need to introduce errors yourself. Each Write only has to return the report the server published for it, which is often an empty `diagnostics` array.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
