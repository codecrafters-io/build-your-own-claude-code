In this stage, you'll connect your existing agent to a language server and
advertise an LSP tool to the model.

### What is a language server?

A language server is a separate program that analyzes source code. It powers
editor features such as finding a function's definition, finding its callers,
and reporting type errors. Editors communicate with it using the **Language
Server Protocol (LSP)**. Your agent can use those same capabilities.

The model chooses what to look up. The language server analyzes the code and
returns locations or errors; your agent returns those results to the model.
Later stages will implement this flow:

```text
Model -> your LSP tool handler -> supplied client/helper -> language server
Model <- tool result          <- supplied client/helper <- server response
```

### What the course supplies

During tests, the tester starts the language server and a helper that handles
its startup protocol and message delivery. The supplied client connects your
program to that helper. You don't install or start a server for graded tests.

The server analyzes a supplied [Python invoice project][example]: `pricing.py`
defines `total(price, quantity)`, and `checkout.py` imports it as `invoice_total`.
Your agent can be written in any supported course language. These are files it
will inspect, not files you add to your solution.

### Your task

Before your first model request:

1. Get the [client for your implementation language][helper] at the listed path
   (Python: `app/lsp_client.py`), and [lsp_tool.json][schema] at your solution's
   root beside `your_program.sh`. New starters include them; copy missing files
   from these links.
2. Construct the client, request its configuration, and keep the returned language
   mapping for later document messages. The tester supplies the connection.
3. Parse `lsp_tool.json` and append its object to your existing `tools` array.
   Include that array in your model requests. The schema describes the tool;
   its operation handler comes in the next stage.

For Python in `app/main.py`, with your existing `tools` list:

```python
import json
from pathlib import Path

from lsp_client import LSPClient

lsp = LSPClient()
configuration = lsp.call("configuration", {})
extension_to_language = configuration["extensionToLanguage"]
schema_path = Path(__file__).resolve().parents[1] / "lsp_tool.json"
tools.append(json.loads(schema_path.read_text(encoding="utf-8")))
```

`configuration` is a helper action; `{}` means it takes no arguments. It returns:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

Later, this mapping identifies `.py` documents as Python.

### Tests

Run `codecrafters test`. It checks configuration retrieval and tool registration,
then asks Read to inspect checkout and pricing. No LSP lookup is required yet.

For running outside the tester, follow the optional [local-server guide][local-run].

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[helper]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#connect-in-one-line
[schema]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/starter_templates/all/code/lsp_tool.json
[local-run]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#run-with-your-own-server
