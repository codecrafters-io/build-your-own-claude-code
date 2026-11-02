In this stage, you'll handle the LSP tool's first operation: `goToDefinition`.

### The first lookup

In the supplied invoice project, `checkout.py` calls `pricing.total` through
the alias `invoice_total`. Definition lookup should follow that call back to
`pricing.py`, where the model can inspect the implementation using Read.

### Handle a definition call

Your existing tool dispatcher will receive arguments like these:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

1. Read the file and convert its absolute path to an encoded file URI.
2. Open the URI once with `client.call("notify", payload)` below. Set languageId
   using the extension mapping saved during setup.
3. Send `client.call("request", payload)` below. Subtract one from both tool coordinates;
   columns count UTF-16 code units.
4. Return the result in the matching model tool result and continue the agent loop.

The **notify** payload opens the file with its complete contents:

```json
{
  "method": "textDocument/didOpen",
  "params": {
    "textDocument": {
      "uri": "file:///project/checkout.py",
      "languageId": "python",
      "version": 1,
      "text": "<complete file contents>"
    }
  }
}
```

The **request** payload asks for the definition:

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

A location result contains a file URI and a zero-based range. Preserve single
locations, arrays, and null results; return protocol errors as tool errors.

### Tests

Tests check that the lookup reaches pricing.total and the model can read it.
Cases cover multiple locations, null, errors, and coordinates. Reuse the client
and tool registration from setup; this stage adds document opening and lookup.
