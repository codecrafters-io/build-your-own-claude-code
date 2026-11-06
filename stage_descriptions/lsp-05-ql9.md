In this stage, you'll report language-server diagnostics to the model so it can repair an API migration.

### Why diagnostics?

A change to one file can break a caller in another. A language-server diagnostic
describes the issue with a message, severity, and source range. Passing new
reports to the model lets it find and repair these mistakes, including problems
in files it hasn't edited.

### Expected feedback

Before each model request, any newly available, current diagnostics must reach
the model through the latest tool result. Each diagnostic needs its relative
file path, message, and one-based start line and character. For example:

```text
<new-diagnostics>The following new diagnostic issues were detected:

checkout.py:
  [Line 5:12] Type Price is not assignable to return type int</new-diagnostics>
```

The wording and grouping can differ. Write keeps its existing success result;
diagnostics arrive as additional feedback on a later turn. Reports for any file
count, including files that the last Write didn't change.

### Current and new reports

Only `textDocument/publishDiagnostics` notifications carry diagnostic reports.
Their version determines whether the contents are current:

| Report | Required behavior |
| --- | --- |
| Version matches the last version sent for that file | Accept the report |
| Version differs from the last version sent for that file | Ignore the report |
| No version supplied | Accept the report |

The latest current report replaces the previous report for that file. An empty
`diagnostics` array clears its earlier issues. Only issues absent from those last
shown for that file should be appended to a tool result. Unchanged issues must
not be repeated on every turn.

### Feedback during a migration

The tester asks the model to migrate the [invoice project][example] using your
agent's tools. The required behavior is:

| Function | Before migration | After migration |
| --- | --- | --- |
| `pricing.total(250, 2)` | Integer `500` | A `Price` TypedDict with an integer `cents` field: `{"cents": 500}` |
| `checkout_total()` | Integer `500` | Integer `500` |
| `report_total()` | Integer `600` | Integer `600` |

Tests and the unrelated `preview.total` must stay unchanged. The model chooses
its edits and uses your agent's diagnostic feedback to repair any type errors.

For example, changing `pricing.total` can make this unchanged caller invalid:

```python
def checkout_total() -> int:
    return invoice_total(250, 2)
```

It now returns a `Price` where its annotation promises an `int`. The language
server can report that mismatch in `checkout.py` even when the last edit was to
`pricing.py`. That report must reach the model so it can repair the caller.

### Read the server's reports

The server sends diagnostics asynchronously in `textDocument/publishDiagnostics`
notifications. They are not the response to `didChange`. Your LSP client queues
them while your agent executes other calls.

The client's `notifications` action reads this queue using a cursor, starting
at `0`:

```json
{ "after": 0, "timeoutMs": 0 }
```

`after` identifies the notifications already read. The response contains newer
notifications and a new cursor for the next call. `timeoutMs: 0` reads queued
messages without waiting for analysis to finish. After the `pricing.py` write
above, a response can contain:

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

Every returned cursor applies to the next queue read, even when the batch is
empty or contains only unrelated notifications. Diagnostic ranges count from
zero, like the locations the server returns for navigation. Convert their start
positions to one-based coordinates for the model.

The model should understand that new diagnostics are feedback to use when
repairing its edits.

### Tests

The tester will create the [invoice project][example] with `test_invoice.py` and execute your program like this:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with an integer cents field. Update checkout.py and reports.py so their results stay unchanged. Before any Write edits, use LSP goToDefinition on checkout.py at line 5, character 12, and LSP findReferences on the returned pricing.total definition. After all Write edits, repeat LSP findReferences at the updated pricing.total definition. That query is required even if the project tests pass. Fix the type errors your tools report. Leave tests and unrelated files unchanged. Run python3 -m unittest -v test_invoice.py and report the result."
<the model's summary of the migration and the test result>
```

The tester will verify that:

- Every current diagnostic the server published, for any file, reaches the model with its file, message, and 1-based line and character
- No diagnostic from a report for an older version reaches the model
- Both lookups run, in either order, before the first Write
- A references lookup runs after the last Write, and its result matches the edited files
- The Bash output shows `Ran 5 tests` and `OK`, `checkout_total()` returns `500`, and `report_total()` returns `600`
- `preview.py` and `test_invoice.py` are unchanged
- Your program exits with code `0`

The tester will also run this prompt against a server that sends stale reports and current reports without a `version`. Its `pricing.py` has a comment line above `def total`, so the definition is not on line 1.

### Notes

- Await asynchronous `notifications` calls before sending the next model request.
- Write's own result stays as it was. Diagnostics reach the model through a later tool result instead.
- A report can arrive after the model request that followed its change. Your agent reads it before the next request.
- The model chooses its own edits, so a run may or may not hit a type error. You don't need to introduce errors yourself.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
