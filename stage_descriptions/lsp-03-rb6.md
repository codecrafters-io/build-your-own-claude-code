In this stage, you'll implement `findReferences` to find the callers affected by an API change.

### Which callers need updating?

We're preparing to change `pricing.total` from an integer to an object with a
`cents` field. Checkout imports it as `invoice_total`. Reporting calls it under
its original name. Preview defines an unrelated `total`.

Searching for `total` requires interpreting those matches.
[References][references] asks the language server for the locations associated
with this particular symbol. Your agent can read those locations before editing.

### Add references to your LSP tool

Add `findReferences` to the operation enum in your tool schema. Reuse document
opening, file URIs, position conversion, and tool-result handling from definition lookup.

For this model tool call:

```json
{
  "operation": "findReferences",
  "filePath": "pricing.py",
  "line": 1,
  "character": 5
}
```

Send action `request` with the complete payload below, using your language's
client-call pattern from earlier stages. The input position 1:5 becomes
LSP position 0:4:

```json
{
  "method": "textDocument/references",
  "params": {
    "textDocument": { "uri": "file:///project/pricing.py" },
    "position": { "line": 0, "character": 4 },
    "context": { "includeDeclaration": true }
  }
}
```

Keep `includeDeclaration` fixed to true. There is no extra model argument.
For the full invoice project under `/project`, the supplied server returns:

```json
[
  {"uri":"file:///project/reports.py","range":{"start":{"line":4,"character":27},"end":{"line":4,"character":32}}},
  {"uri":"file:///project/reports.py","range":{"start":{"line":4,"character":11},"end":{"line":4,"character":16}}},
  {"uri":"file:///project/reports.py","range":{"start":{"line":0,"character":20},"end":{"line":0,"character":25}}},
  {"uri":"file:///project/checkout.py","range":{"start":{"line":4,"character":11},"end":{"line":4,"character":24}}},
  {"uri":"file:///project/checkout.py","range":{"start":{"line":0,"character":20},"end":{"line":0,"character":25}}},
  {"uri":"file:///project/pricing.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
]
```

Return every location in the response to the model. Each contains a URI and a
zero-based range. Preserve the server's results. Don't reconstruct or filter
them by spelling. Different servers can represent aliased references differently.
For example, Pyright returns checkout's import of `total`, rather than the
`invoice_total` call. The model reads that file to find the affected call.
An empty array or null means there were no results.

### Tests

The first case supplies the invoice project without `reports.py` and runs:

```bash
$ ./your_program.sh -p "Use LSP findReferences on pricing.py at line 1, character 5. Identify every affected caller before changing its return type. Preserve the returned locations; preview.total and comments are unrelated."
```

The matching tool result must preserve these locations, with the actual project
URI substituted:

```json
[
  {"uri":"file:///project/checkout.py","range":{"start":{"line":4,"character":11},"end":{"line":4,"character":24}}},
  {"uri":"file:///project/checkout.py","range":{"start":{"line":0,"character":20},"end":{"line":0,"character":25}}},
  {"uri":"file:///project/pricing.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
]
```

Other cases cover callers across files and an empty result. The tester checks
`includeDeclaration` and every returned location. The final explanation can vary.

[references]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references
