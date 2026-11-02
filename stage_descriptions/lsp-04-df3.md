In this stage, you'll add support for the `goToDefinition` operation.

### The `goToDefinition` operation

Consider this call in `checkout.py`:

```python
from pricing import total as invoice_total

amount = invoice_total(250, 2)
```

The call uses the name `invoice_total`, but the function is defined as `total`
in `pricing.py`. Searching for `def invoice_total` won't find it.

The
[`textDocument/definition`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition)
request follows the name at the call site to the function's definition.

### Requesting a definition

Add `goToDefinition` to your LSP tool's operations. It takes the same
`filePath`, `line`, and `character` arguments as `hover`.

Open the document if necessary, then send:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///path/to/project/checkout.py" },
    "position": { "line": 2, "character": 9 }
  }
}
```

The server can return a `Location`:

```json
{
  "uri": "file:///path/to/project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

A `Location` tells you which file contains the definition and where to find it.
Its `range` starts at `total` and ends just after it. Both positions are
zero-based. The server can also return an array of locations, or `null` when it
can't find a definition.

Return this result to the model, just as you do for `hover`. The model can then
use `Read` to inspect the implementation. Your handler only needs to return the
location.

### Tests

The tester will create the example project with an imported alias and run:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 3, character 10. Report the definition location."
```

The server returns this location, which must reach the model in the matching
tool result:

```json
{
  "uri": "file:///path/to/project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

The tester uses the actual workspace URI. It also checks multiple locations, a
missing definition, and an unrelated function of the same name.

### Notes

- You can reuse the connection, document-opening code, and position arguments
  from `hover`.
- Don't advertise `textDocument.definition.linkSupport`. The test server returns
  `Location`, `Location[]`, or `null`, so you don't need `LocationLink` support.
