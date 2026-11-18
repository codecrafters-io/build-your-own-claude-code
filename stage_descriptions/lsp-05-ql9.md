In this stage, you'll return language-server diagnostics to the model so it
can repair an API migration across files.

### Why diagnostics?

Your `Write` tool saves edits and updates the language server. A successful
save can still break a caller elsewhere. The server detects type errors without
running the program and reports them as **diagnostics**, each with a message,
severity, and source range.

Suppose `pricing.total` starts returning a dictionary. This caller still
promises an integer:

```python
def checkout_total() -> int:
    return invoice_total(250, 2)
```

The server can report the mismatch in `checkout.py` even though the last edit
was to `pricing.py`. Returning that report lets the model repair the caller.

### The migration

The tester asks the model to make these changes to the [invoice project][example]:

| Function | Before migration | After migration |
| --- | --- | --- |
| `pricing.total(250, 2)` | Integer `500` | A `Price` TypedDict with an integer `cents` field: `{"cents": 500}` |
| `checkout_total()` | Integer `500` | Integer `500` |
| `report_total()` | Integer `600` | Integer `600` |

A `TypedDict` describes a dictionary's keys and value types. The model chooses
the edits through your tools.

### Read the diagnostic queue

Diagnostics arrive in `textDocument/publishDiagnostics` notifications,
independently of `didChange`. The supplied client exposes a queue of these
messages.

Before each model request, read the queue with the client's `notifications`
action:

```json
{ "after": 0, "timeoutMs": 0 }
```

`after` is a cursor marking how far you've read, initially `0`.
`timeoutMs: 0` reads without waiting for analysis to finish. A response can
contain:

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

Use the returned cursor for the next read, even for empty or unrelated batches.
Process only `textDocument/publishDiagnostics` notifications.

### Select current, new issues

Compare each report's version with the last version your agent sent for that file:

| Report | Required behavior |
| --- | --- |
| Version matches | Accept the report |
| Version differs | Ignore the report |
| No version supplied | Accept the report |

The latest accepted report replaces the previous report for that file. An empty
`diagnostics` array clears its issues. Track the issues last shown for each file
and send only new ones. Unchanged issues must not repeat. An issue that clears
and later reappears is new again.

Process reports for every file, including files the last `Write` left untouched.

### Return feedback

Append new diagnostics to the latest tool result before the model request,
preserving `Write`'s normal success result. Include each issue's relative path,
message, and one-based start position, using the navigation coordinate conversion:

```text
<new-diagnostics>The following new diagnostic issues were detected:

checkout.py:
  [Line 5:12] Type Price is not assignable to return type int</new-diagnostics>
```

The wording and grouping can differ. Tell the model to repair reported issues.
Reports arriving after a model request are read before the next request.

### Tests

The tester creates the invoice project with `test_invoice.py` and runs:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with an integer cents field. Update checkout.py and reports.py so their results stay unchanged. Before any Write edits, use LSP goToDefinition on checkout.py at line 5, character 12, and LSP findReferences on the returned pricing.total definition. After all Write edits, repeat LSP findReferences at the updated pricing.total definition. That query is required even if the project tests pass. Fix the type errors your tools report. Leave tests and unrelated files unchanged. Run python3 -m unittest -v test_invoice.py and report the result."
<the model's summary of the migration and the test result>
```

The tester will verify that:

- Current diagnostics reach the model with their file, message, and one-based line and character
- Stale diagnostics never reach the model
- Definition and references lookups run, in either order, before the first `Write`
- A references lookup after the last `Write` matches the edited files
- `Bash` output shows `Ran 5 tests` and `OK`. `checkout_total()` returns `500` and `report_total()` returns `600`
- `preview.py` and `test_invoice.py` are unchanged
- Your program exits with code `0`

Another case sends stale and unversioned reports. Its `pricing.py` starts with
a comment, shifting the definition away from line 1.

### Notes

- Await asynchronous `notifications` calls before sending the next model request.
- The model may complete the migration without type errors. Don't introduce errors deliberately.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
