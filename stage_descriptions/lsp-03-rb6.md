In this stage, you'll find the callers affected by an API change.

### Which callers need updating?

We're preparing to change `pricing.total` from an integer to an object with a
`cents` field. Checkout imports it as `invoice_total`; reporting calls it under
its original name. Preview defines an unrelated `total`.

Searching for `total` requires interpreting those matches.
[References][references] asks the language server for the locations associated
with this particular symbol. Your agent can read those locations before editing.

### Add references to your LSP tool

Add `findReferences` to the operation enum in your tool schema. Reuse document
opening, file URIs, position conversion, and tool-result handling from definition lookup.

For a call on `pricing.total`, pass this complete object to
`client.call("request", payload)`, as in the definition stage:

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

Return every location in the response to the model. Each contains a URI and a
zero-based range. Preserve the server's results; don't reconstruct or filter
them by spelling. Different servers can represent aliased references differently.
An empty array or null means there were no results.

### Tests

The tester asks your agent:

```text
Use LSP findReferences on pricing.py at line 1, character 5.
Identify the callers affected by changing its return type.
```

It checks that the request includes the declaration and that all returned
locations reach the matching tool result. Cases cover an aliased caller,
multiple source files, unrelated names and comments, and no references.

The visible payoff is a list of affected pricing locations in checkout and
reporting, with unrelated preview code excluded. Your handler returns locations;
the model uses the existing Read tool to inspect them.

[references]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references
