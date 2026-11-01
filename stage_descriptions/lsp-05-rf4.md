In this stage, you'll add support for the `findReferences` operation.

### Finding where a function is used

Your agent can now find a function's definition. Before changing that function,
it also helps to find the code that uses it, so the agent can check which calls
might be affected.

For example, this code imports `total` from `pricing.py` under the name
`invoice_total`:

```python
from pricing import total as invoice_total

amount = invoice_total(250, 2)
```

The call refers to `pricing.total`, even though it uses the name
`invoice_total`. Another file could define an unrelated `total` function. Your
agent needs the locations that refer to this particular function.

The `findReferences` operation asks the language server where a particular
symbol is used. Returning those locations lets the model inspect the uses with
`Read` before deciding how to change the code. Your program passes on the
server's results without filtering them by spelling.

### Requesting references

Add `findReferences` to the LSP tool's operations. It takes `filePath`, `line`,
and `character`, just like `goToDefinition`. The tool's positions start at `1`.

Open the source file if needed, convert the position to zero-based coordinates,
then send a
[`textDocument/references`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references)
request:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "textDocument/references",
  "params": {
    "textDocument": { "uri": "file:///path/to/project/pricing.py" },
    "position": { "line": 0, "character": 4 },
    "context": { "includeDeclaration": true }
  }
}
```

Use `includeDeclaration: true`, as Claude Code does. This includes the symbol's
definition as well as its uses. It is fixed for this operation, so there's no
extra tool argument to parse.

Return every location in the result to the model. An empty array or `null` means
the server found no references. The server searches across files, so your
program only needs to open the file named in the request.

### Tests

The tester will create `pricing.py` and a `checkout.py` whose imported alias is
called on line `4`, then run:

```bash
$ ./your_program.sh -p "Use LSP findReferences on pricing.py at line 1, character 5. Report every returned location."
```

Its server returns these three locations, in any order:

```json
[
  {
    "uri": "file:///path/to/project/pricing.py",
    "range": {
      "start": { "line": 0, "character": 4 },
      "end": { "line": 0, "character": 9 }
    }
  },
  {
    "uri": "file:///path/to/project/checkout.py",
    "range": {
      "start": { "line": 0, "character": 20 },
      "end": { "line": 0, "character": 25 }
    }
  },
  {
    "uri": "file:///path/to/project/checkout.py",
    "range": {
      "start": { "line": 4, "character": 11 },
      "end": { "line": 4, "character": 24 }
    }
  }
]
```

All three must reach the model. Other cases include several source files,
unrelated names and comments, and empty results.

### Notes

- Different servers can treat aliases differently. Preserve the locations the
  configured server returns rather than implementing a name-based search.
- Results can arrive in any order. You can preserve that order or sort them.
