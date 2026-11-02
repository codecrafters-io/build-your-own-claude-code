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

### Return the location to the model

The helper returns the server's result, for example:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

This identifies `total` on the first line of `pricing.py`. The returned range
stays zero-based; only incoming model tool coordinates are converted.

Use your existing tool-result handling to send this value back. For example,
in Python, `result` is the helper response and `tool_call` is the model's call:

```python
messages.append({
    "role": "tool",
    "tool_call_id": tool_call["id"],
    "content": json.dumps(result),
})
```

Continue the loop. The model can decode the URI and request Read with
`file_path: "/project/pricing.py"` to inspect the implementation. Use the
actual project path in place of `/project` throughout these examples.

Preserve single locations, arrays, and null results; return protocol errors as
tool errors.

### Tests

Tests check that the lookup reaches pricing.total and the model can read it.
Cases cover multiple locations, null, errors, and coordinates. Reuse the client
and tool registration from setup; this stage adds document opening and lookup.
