In this stage, you'll report language-server diagnostics to the model so it can repair an API migration.

### Why diagnostics?

Your agent already sends each Write to the language server. The server can also
report problems in the code. A diagnostic describes an issue in a file, with a
message, severity, and source range.

A change to one file can break another. The server re-checks every open file
after a change, so it can report an error in a caller the model hasn't touched.

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

Suppose the model writes the new `pricing.py` first. `checkout.py` is still
open from the earlier definition lookup, and its unchanged return statement now
returns a `Price` from a function declared to return an `int`:

```python
def checkout_total() -> int:
    return invoice_total(250, 2)
```

The language server reports that mismatch in `checkout.py`, even though nothing
wrote to it. Your agent passes the report on, so the model can fix the caller by
returning `invoice_total(250, 2)["cents"]`.

### Read the server's reports

The server sends diagnostics asynchronously in `textDocument/publishDiagnostics`
notifications. They are not the response to `didChange`. Your LSP client queues
them while your agent executes other calls.

Keep a notification cursor for the whole run, like the document-version map,
and initialize it to `0`. Read queued notifications with `call` and
`"notifications"`, passing this payload:

```json
{ "after": 0, "timeoutMs": 0 }
```

Use your saved cursor as `after`. It counts the notifications you've already
read, so the response holds only newer ones, plus a new `cursor` to pass next
time. A zero timeout drains queued messages without waiting. After the
`pricing.py` write above, the response contains:

```json
{
  "cursor": 4,
  "notifications": [
    {
      "method": "textDocument/publishDiagnostics",
      "params": {
        "uri": "file:///project/checkout.py",
        "version": 1,
        "diagnostics": [
          {
            "range": {
              "start": { "line": 4, "character": 11 },
              "end": { "line": 4, "character": 32 }
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
unrelated messages. Diagnostic ranges count from zero, like navigation results.

### Report new diagnostics to the model

Claude Code doesn't wait for diagnostics inside Write. It collects them in the
background and shows the model what's new on its next turn. Do the same before
each model request:

1. **Read queued notifications** with a zero timeout and save the cursor.
2. **Keep the current report for each file.** Use only
   `textDocument/publishDiagnostics`. Skip a report whose `version` doesn't
   match the version you last sent for that file. A report with no `version` is
   current. If a file has several current reports, the latest replaces the
   earlier ones, and an empty `diagnostics` array means the file is clean.
3. **Find what's new.** Compare each file's current diagnostics with the ones
   you last showed the model for that file, and keep the ones it hasn't seen.
4. **Append them to the latest tool result**, with relative paths and 1-based
   positions, as in navigation results. Claude Code uses this block:

```text
<new-diagnostics>The following new diagnostic issues were detected:

checkout.py:
  ✘ [Line 5:12] Type Price is not assignable to return type int</new-diagnostics>
```

The tester checks that each diagnostic's file, message, and 1-based line and
character reach the model, not the exact wording. In JavaScript, TypeScript,
and C#, `await` each `notifications` call.

### Tell the model to use the reports

Add this line to your system prompt, alongside the LSP guidance it already has:

```text
Fix the issues reported in new diagnostics.
```

### Tests

The tester will create the [invoice project][example] with `test_invoice.py` and execute your program like this:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with an integer cents field. Update checkout.py and reports.py so their results stay unchanged. Before any Write edits, use LSP goToDefinition on checkout.py at line 5, character 12, and LSP findReferences on the returned pricing.total definition. After all Write edits, repeat LSP goToDefinition on the invoice_total call in checkout.py at its current line and character, and LSP findReferences at the updated pricing.total definition, using the position it returns. Both post-edit LSP queries are required even if the project tests pass. Fix the type errors your tools report. Leave tests and unrelated files unchanged. Run python3 -m unittest -v test_invoice.py and report the result."
<the model's summary of the migration and the test result>
```

The tester will verify that:

- Every current diagnostic the server published, for any file, reaches the model with its file, message, and 1-based line and character
- No diagnostic from a report for an older version reaches the model
- Both lookups run, in either order, before the first Write and again after the last Write, and the follow-up references match the edited files
- The model reads `pricing.py`, `checkout.py`, and `reports.py` before writing each one
- The Bash output shows `Ran 5 tests` and `OK`, `checkout_total()` returns `500`, and `report_total()` returns `600`
- `preview.py` and `test_invoice.py` are unchanged
- Your program exits with code `0`

The tester will also run this prompt against a server that sends stale reports and current reports without a `version`. Its `pricing.py` has a comment line above `def total`, so the definition is not on line 1.

### Notes

- Write's own result stays as it was. Diagnostics reach the model through a later tool result instead.
- A report can arrive after the model request that followed its change. Your agent reads it before the next request.
- The model chooses its own edits, so a run may or may not hit a type error. You don't need to introduce errors yourself.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
