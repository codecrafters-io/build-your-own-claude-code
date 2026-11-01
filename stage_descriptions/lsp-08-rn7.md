In this stage, you'll add support for the `rename` operation.

### The `rename` operation

Say the user asks to rename `pricing.total` to `total_cents`. The definition
needs to change, along with its imports and callers. An unrelated function named
`total` should stay as it is.

The
[`textDocument/rename`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_rename)
request returns the edits needed for this rename. Your program applies those
edits to the files.

### Requesting a rename

Add `rename` to your LSP tool's operations. It takes the usual file and position
arguments, plus a required `new_name`. Send:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "textDocument/rename",
  "params": {
    "textDocument": { "uri": "file:///path/to/project/pricing.py" },
    "position": { "line": 0, "character": 4 },
    "newName": "total_cents"
  }
}
```

The result is a `WorkspaceEdit`, which groups the edits by file URI. Each edit
gives a range to replace and the new text to put there:

```json
{
  "changes": {
    "file:///path/to/project/pricing.py": [
      {
        "range": {
          "start": { "line": 0, "character": 4 },
          "end": { "line": 0, "character": 9 }
        },
        "newText": "total_cents"
      }
    ]
  }
}
```

### Applying the edits

Read each file in `changes` and replace its ranges with `newText`. As with
locations, a range excludes its end position. Its character offsets count UTF-16
code units, so convert them to your string library's offsets before slicing.
Some characters take two code units.

All the ranges refer to the original text. Start with the edit nearest the end
of the file and work backward. Otherwise, changing `total` to `total_cents`
shifts the positions of later occurrences. Sort the edits yourself if needed.

Prepare the new contents of every file before writing. Then save them using the
same code as your `Write` tool, including synchronization and diagnostics.
Return the changed paths and diagnostics to the model. If the server returns
`null`, there are no edits to apply.

### Tests

The tester will create the invoice project and run:

```bash
$ ./your_program.sh -p "Use LSP rename on pricing.py at line 0, character 4, with new name total_cents."
```

The changed definition must be:

```python
def total_cents(price: int, quantity: int) -> int:
    return price * quantity
```

The checkout import must become:

```python
from pricing import total_cents as invoice_total
```

The tester checks the saved files, synchronization, and diagnostics. The
`invoice_total` alias, unrelated function, comment, and string must stay
unchanged. Other cases include unsorted edits, multiple replacements on one
line, UTF-16 offsets, and no edits.

### Notes

- The server advertises `renameProvider`. Tests use only `WorkspaceEdit.changes`
  with non-overlapping edits to existing files. Don't advertise
  `workspace.workspaceEdit.documentChanges` support.
- Do not implement rename using search-and-replace or by asking the model to
  rewrite the files. Applying the returned edits is the work in this stage.
