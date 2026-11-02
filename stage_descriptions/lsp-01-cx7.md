In this stage, you'll connect your agent to a language server and advertise
an LSP tool.

### What is a language server?

A language server analyzes code to find definitions, find callers, and report
type errors. Editors communicate with it using the **Language Server Protocol
(LSP)**. Your agent can too. See the [official introduction][lsp].

- **Model (LLM):** The language model from earlier stages. It chooses tool calls.
- **Your agent:** Your program's loop and tool handlers. It executes calls and
  returns results to the model.
- **Language server:** A separate program returning code locations or diagnostics
  (such as type errors).

### What the course supplies

The tester starts the language server and a helper for startup and message
delivery. The supplied client connects your agent to the helper. No server
installation is needed.

The supplied [Python invoice project][example] defines `total(price, quantity)`
in `pricing.py`; `checkout.py` imports it as `invoice_total`. These files are test
inputs. Your agent can use any supported course language.

### Example: the lookup you'll build in later stages

Suppose the user asks: "Find the function that calculates the checkout total."

1. **Read the caller.** The model requests Read for `checkout.py`. Your agent
   reads the file and returns its contents:

   ```python
   from pricing import total as invoice_total


   def checkout_total() -> int:
       return invoice_total(250, 2)
   ```

2. **Ask where the function is defined.** Having seen the call, the model can
   request your `LSP` tool with `operation: "goToDefinition"`, pointing at
   `invoice_total` in `checkout.py`.
3. **Run the lookup.** Your agent's tool handler sends the file contents and
   definition request through the supplied client/helper. The language server
   resolves the alias to `total` in `pricing.py` and returns that location.
4. **Return the location.** Your agent sends it back to the model as the result
   of its `LSP` tool call.
5. **Read the implementation.** The model requests Read for `pricing.py`.
   Your agent returns the file contents so the model can explain the calculation.

The model chooses tool calls; your agent executes them. The model does not contact
the language server directly. This stage only sets up the connection and
advertises the tool; you'll implement the lookup next.

### Your task

Before your first model request:

1. Find your language in the [client guide][helper]. Check the listed path in
   your solution (Python: `app/lsp_client.py`). If missing, copy the linked client
   there. Import it into the code running your agent loop.
2. In that code, create one client before entering the loop. Call its
   `configuration` action with `{}` and store the returned `extensionToLanguage`
   mapping alongside the client, where your tool handlers can access both.
3. Add the JSON object shown below directly to your existing `tools` list,
   alongside Read, Write, and Bash. Include that list in your model requests.

Python setup:

```python
from lsp_client import LSPClient

lsp = LSPClient()
configuration = lsp.call("configuration", {})
extension_to_language = configuration["extensionToLanguage"]
```

The tester supplies the connection. `configuration` is a helper action, not an
LSP message; `{}` takes no arguments. It returns:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

Later, this mapping identifies `.py` documents as Python.

### Advertise the LSP tool

Implement this tool's handler in the next stage.

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Resolve a symbol using the language server. Positions are one-based UTF-16.",
    "parameters": {
      "type": "object",
      "properties": {
        "operation": {
          "type": "string",
          "enum": ["goToDefinition"]
        },
        "filePath": {
          "type": "string"
        },
        "line": {
          "type": "integer",
          "minimum": 1
        },
        "character": {
          "type": "integer",
          "minimum": 1
        }
      },
      "required": ["operation", "filePath", "line", "character"]
    }
  }
}
```

### Tests

Run `codecrafters test`. It checks configuration retrieval and tool registration,
then asks Read to inspect checkout and pricing. No LSP lookup is required yet.

For running outside the tester, follow the optional [local-server guide][local-run].

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[helper]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#connect-in-one-line
[local-run]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#run-with-your-own-server
[lsp]: https://microsoft.github.io/language-server-protocol/
