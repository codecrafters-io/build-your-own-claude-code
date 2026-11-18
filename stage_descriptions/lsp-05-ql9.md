In this stage, you'll feed language-server error reports back into your agent
loop so the model can repair problems its edits introduce. You'll combine this
feedback with navigation and synchronized edits to complete an API migration
across files.

### Why diagnostics?

A successful `Write` means the file was saved. The change can still break a
caller in another file. The language server can detect problems such as a
function returning the wrong type without running the program.

It reports each problem as a **diagnostic**, with a message, severity, and
source range. Passing those reports to the model lets it locate and repair
mistakes, including problems in files it hasn't edited.

### Feedback during a migration

The tester asks the model to migrate the [invoice project][example] using your
agent's tools. The required behavior is:

| Function | Before migration | After migration |
| --- | --- | --- |
| `pricing.total(250, 2)` | Integer `500` | A `Price` TypedDict with an integer `cents` field: `{"cents": 500}` |
| `checkout_total()` | Integer `500` | Integer `500` |
| `report_total()` | Integer `600` | Integer `600` |

Here, `Price` is a `TypedDict`, a Python type that specifies a dictionary's keys
and value types. The function will return a dictionary, while checkout and
reporting must continue returning integers. Tests and the unrelated
`preview.total` must stay unchanged.

The model chooses and applies these edits through your tools. Your program
supplies the diagnostic feedback it needs to repair any type errors.

For example, changing `pricing.total` can make this unchanged caller invalid:

```python
def checkout_total() -> int:
    return invoice_total(250, 2)
```

It now returns a `Price` where its annotation promises an `int`. The language
server can report that mismatch in `checkout.py` even when the last edit was to
`pricing.py`. That report must reach the model so it can repair the caller.

### Read the server's reports

Saving a file and analyzing its consequences are separate steps. The server
sends `textDocument/publishDiagnostics` notifications as analysis finishes,
independently of your `didChange` call. These messages wait in a queue that
your agent can read through the supplied client.

Before each model request, use the client's `notifications` action to read
this queue. It takes a cursor, a number marking how far you've read, starting
at `0`:

```json
{ "after": 0, "timeoutMs": 0 }
```

Set `after` to the cursor from the previous read. The response contains newer
notifications and the cursor to use next. `timeoutMs: 0` reads queued messages
without waiting for analysis to finish. After the `pricing.py` write above, a
response can contain:

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

Always advance to the returned cursor, even when the batch is empty or contains
only unrelated notifications. Process the `textDocument/publishDiagnostics`
notifications using the rules below.

### Keep current reports and avoid repeated feedback

A report can describe a version of a file that your agent has already replaced.
Use the document versions you tracked in the previous stage to decide whether
to accept it:

| Report | Required behavior |
| --- | --- |
| Version matches the last version sent for that file | Accept the report |
| Version differs from the last version sent for that file | Ignore the report |
| No version supplied | Accept the report |

The latest current report replaces the previous report for that file. An empty
`diagnostics` array clears its earlier issues. Compare the current issues with
those last shown to the model for that file, and send only the new ones.
Unchanged issues must not be repeated on every turn. If an issue clears and
later reappears, it is new again.

Reports for any file count, including files that the last `Write` didn't
change. A change to `pricing.py` can produce a diagnostic for `checkout.py`,
whose own document version hasn't changed.

### Return the feedback to the model

Keep `Write`'s existing success result. After reading the queue and selecting
new, current diagnostics, append them to the latest tool result before sending
the next model request. Each issue needs its relative file path, message, and
one-based start line and character. Use the same coordinate conversion as for
navigation. For example:

```text
<new-diagnostics>The following new diagnostic issues were detected:

checkout.py:
  [Line 5:12] Type Price is not assignable to return type int</new-diagnostics>
```

The wording and grouping can differ. Tell the model to use these reports when
repairing its edits. A report that arrives after a model request will be read
before the next request.

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
- The model chooses its own edits, so a run may or may not hit a type error. You don't need to introduce errors yourself.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
