In this stage, you'll add support for the `references` operation.

### The `references` operation

You can now find where a function is defined. To change that function, you might
also need to find the code that uses it.

The `total` function from `pricing.py` can be imported as `invoice_total` in one
file and called as `total` in another. A separate function can also be named
`total`. Searching for the name alone won't tell you which uses belong to the
function you want.

The language server's
[`textDocument/references`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references)
request returns the locations that refer to the symbol at a given position.

### Requesting references

Add `references` to your LSP tool's operations. It uses the same file and
position arguments as `definition`, plus a required boolean argument named
`include_declaration`. This controls whether the result includes the function's
definition. Explain the argument in the tool description.

Here's the request when `include_declaration` is `false`:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "textDocument/references",
  "params": {
    "textDocument": { "uri": "file:///path/to/project/pricing.py" },
    "position": { "line": 0, "character": 4 },
    "context": { "includeDeclaration": false }
  }
}
```

Open the source file if needed, then send the request. Return every location in
the result to the model. An empty array or `null` means the server didn't find
any references.

The server handles the search across files. Your program only needs to open the
file named in the request, even when the results point to other files.

### Tests

The tester will create `pricing.py` and a `checkout.py` that imports the
function as `invoice_total`, then run:

```bash
$ ./your_program.sh -p "Use LSP references on pricing.py at line 0, character 4, without the declaration. Report every returned location."
```

For a caller with an import on line `0` and a call on line `4`, the server
returns:

```json
[
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

The tester checks that both locations reach the model. Other cases include calls
using the original name, unrelated names and comments, empty results, results in
a different order, and `includeDeclaration: true`.

### Notes

- Don't filter the result by comparing symbol names. The alias is a reference
  even though it is spelled differently.
- The server may return locations in any order. Preserve them or sort them for
  readability. The tester won't require a particular order.
