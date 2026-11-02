In this stage, you'll connect your existing agent to the supplied LSP helper.

### Meet the example project

The tests put a small Python invoice project in your agent's working directory.
You can [inspect the example files][example] before running them through your
agent. You don't need to copy them into your solution.

`pricing.py` defines `total(price, quantity)`. `checkout.py` imports it as
`invoice_total`. In the next stage, your agent will follow that call back to
its implementation. Later, it will change the function and repair a caller
using error feedback.

### Connect with the supplied client

The helper starts and initializes the language server. Your starter includes
a client for your implementation language and `lsp_tool.json`, the model-facing
tool schema. See the [client guide][helper] for your language's import and
constructor.

When CODECRAFTERS_LSP_URL is set, create the client and read its configuration.
For example, in Python:

```python
from lsp_client import LSPClient

lsp = LSPClient()
configuration = lsp.call("configuration", {})
```

The test configuration returns:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

Keep the client and mapping for later tool calls. Python is the analyzed
language; your agent can use any supported course language.

### Advertise the tool

Add the supplied `lsp_tool.json` object to your existing tools array. When the
connection URL is absent, use your original tools without LSP.

Tests check the configuration request and advertised schema, then ask the
agent to inspect the example using its existing Read tool. No LSP tool calls
or document messages are required yet.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[helper]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#connect-in-one-line
