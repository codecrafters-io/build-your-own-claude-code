In this stage, you'll connect the supplied LSP client, retrieve configuration,
and advertise the LSP tool. The definition handler comes next.

### Your task

Before your first model request:

1. Import your language's client from the [client guide][helper]
   (Python: `app/lsp_client.py`). Current starters include it; older checkouts
   may need to copy the linked file to that path.
2. Create one client before the agent loop. Call `configuration` with `{}` and
   save the returned `extensionToLanguage` mapping alongside the client.
3. Add the tool specification below to your existing `tools` list alongside
   Read, Write, and Bash. Include it in your model requests.

Python setup:

```python
from app.lsp_client import LSPClient

lsp = LSPClient()
configuration = lsp.call("configuration", {})
extension_to_language = configuration["extensionToLanguage"]
```

`configuration` is a helper action, not an LSP message. It takes no arguments
and returns:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

Keep this mapping accessible to your future tool handler.

### Advertise the LSP tool

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Resolve a symbol using the language server. Accepts one-based input positions. Returns raw LSP results with file URIs and zero-based UTF-16 ranges. Edit files with Write so the language server sees changes.",
    "parameters": {
      "type": "object",
      "properties": {
        "operation": {
          "type": "string",
          "enum": ["goToDefinition"]
        },
        "filePath": {
          "type": "string",
          "description": "Absolute path, or a path relative to the agent's current working directory."
        },
        "line": {
          "type": "integer",
          "minimum": 1,
          "description": "1-based line number of the symbol."
        },
        "character": {
          "type": "integer",
          "minimum": 1,
          "description": "1-based character offset in UTF-16 code units (same as character count for ASCII)."
        }
      },
      "required": ["operation", "filePath", "line", "character"]
    }
  }
}
```

### How the pieces connect

A language server analyzes code to locate definitions, callers, and type errors.
Editors communicate with it using the **Language Server Protocol (LSP)**;
see the [official introduction][lsp].

The model chooses tool calls. Your agent executes them through this connection:

```text
Agent -> supplied client -> helper -> language server
```

The tester starts the helper and server and supplies the connection. The client
sends your calls to the helper, which handles startup and message delivery.
Results travel back to your agent, which returns tool results to the model.
No server installation is needed.

### Where this is going

The supplied [invoice project][example] contains:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

Next stage, the model can Read `checkout.py`, call LSP on `invoice_total`, then
Read the returned definition in `pricing.py`. These are Python test inputs;
your agent can use any supported course language.

### Tests

Run `codecrafters test`. It observes the `configuration` call and inspects the
first model request's `tools` array for the required parameter names, types,
and `goToDefinition` enum value. Descriptions need not match exactly.

The test prompt tells the model to use only Read for `checkout.py` and
`pricing.py`; no LSP lookup is required.

For local runs, follow the [local-server guide][local-run]. If a live model
calls LSP before stage 2, return a "not implemented yet" tool result with the
matching `tool_call_id`.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[helper]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#connect-in-one-line
[local-run]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#run-with-your-own-server
[lsp]: https://microsoft.github.io/language-server-protocol/
