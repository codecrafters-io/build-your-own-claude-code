In this stage, you'll let your agent find the function behind a call using
`goToDefinition`.

### Why look up a definition?

Suppose the user asks: "How is the checkout total calculated?" After reading
`checkout.py` in the supplied invoice project, the model sees:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

`invoice_total` is an alias for `pricing.total`. The model requests
`goToDefinition` to locate the function, then Read to see how it calculates
the total.

### Handle a definition call

When the model calls your `LSP` tool to find a definition (`goToDefinition`),
your dispatcher passes these arguments to the handler:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

This selects `invoice_total` at line 5, character 12 in `checkout.py`.
Reuse the `lsp` client and extension mapping from setup.

### 1. Give the server the source file

Inside your handler, read `filePath` (`checkout.py`) from disk. Resolve its
absolute path and convert it to an encoded file URI. These examples assume
`/project/checkout.py`; use your actual project path.

On the first lookup for each URI, send `lsp.call("notify", payload)` with this
[`didOpen` payload][did-open]. Fill `text` with the complete file contents and
get `languageId` from the saved extension mapping (`.py` maps to `python`).

```json
{
  "method": "textDocument/didOpen",
  "params": {
    "textDocument": {
      "uri": "file:///project/checkout.py",
      "languageId": "python",
      "version": 1,
      "text": "<complete contents of checkout.py>"
    }
  }
}
```

Track opened URIs so later lookups reuse the document.

### 2. Ask where the function is defined

Send `result = lsp.call("request", payload)` with this
[`definition` payload][definition]. Use the same URI. Subtract one from the
tool's line and character because LSP positions start at zero. Both use UTF-16
code units for columns (see [positions][position]).

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

### 3. Return the location to the model

For this call, the server returns the location of `total` in `pricing.py`:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

Serialize `result` into your existing tool-result message with the matching
`tool_call_id`. Preserve single locations, arrays, null, and zero-based ranges;
return protocol errors as tool errors. Continue the loop so the model can
request Read for `/project/pricing.py` and explain the calculation.

### Tests

Run `codecrafters test`. It checks document opening, lookup coordinates, returned
locations, null results, errors, and the model's follow-up Read.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
