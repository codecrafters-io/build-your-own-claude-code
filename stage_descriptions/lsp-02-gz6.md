In this stage, you'll let your agent find the function behind a call using
`goToDefinition`.

### Why look up a definition?

To explain checkout's calculation, the model reads `checkout.py`:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

`goToDefinition` resolves `invoice_total` to `pricing.total`; Read retrieves
its implementation.

### Handle a definition call

Reuse setup's client and extension mapping. Handle this model tool call:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

### 1. Give the server the source file

`filePath` follows the same rule as Read and Write:
"Absolute path, or a path relative to the agent's current working directory."
The tester runs your agent in the invoice project directory.

Read the file and encode its absolute path as a URI. In Python:

```python
from pathlib import Path

path = Path(arguments["filePath"]).resolve()
uri = path.as_uri()
text = path.read_text(encoding="utf-8")
```

Examples use `/project/checkout.py`; substitute your actual path.

On each URI's first lookup, send `lsp.call("notify", payload)` with this
[`didOpen` payload][did-open]. Supply complete file contents and the mapped
`languageId` (`.py` gives `python`).

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

Wait for `notify` to finish (`await` asynchronous clients): it returns null
after writing the notification, before your subsequent request.
Track opened URIs; stage 4 adds synchronization after Write.

### 2. Ask where the function is defined

Send `result = lsp.call("request", payload)` with this
[`definition` payload][definition]. Reuse the URI; subtract one from input line
and character. LSP [positions][position] are zero-based with UTF-16 columns.

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

The server returns `total` in `pricing.py`:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

Set tool-message `content` to JSON text, preserving locations, arrays, null,
URIs, and zero-based ranges. Match `tool_call_id` and continue the loop.
Python uses `json.dumps(result)`; `None` becomes content `"null"`.

Clients returning serialized JSON (Java, C#, C, Zig) already supply that text;
Go uses `string(result)` for its `json.RawMessage`.
Do not JSON-encode it again: that produces a quoted, escaped string.

The model must decode file URIs into paths for Read and add one to returned
line/character values before reusing them as LSP inputs.

### Errors

Python raises `RuntimeError` containing the helper's response text, including
the server message and code. Go returns an error alongside its result.
For server errors, unknown operations, missing files, and unmapped extensions,
we recommend the same tool-result shape:

```python
content = json.dumps({"error": str(error)})
```

Use the matching `tool_call_id`; keep the loop running.

### Tests

Run `codecrafters test`. Cases cover a location plus follow-up Read, an array,
null, and error `-32603` (`"Definition unavailable"`). The error message must
reach the model.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
