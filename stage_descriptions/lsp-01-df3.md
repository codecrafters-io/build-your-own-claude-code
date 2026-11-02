In this stage, you'll add an LSP tool that follows a call to its implementation.

### The first lookup

The tests supply a Python invoice project in your agent's working directory;
you don't create it. Its `checkout.py` imports `total` from `pricing.py` as
`invoice_total`. Definition lookup should follow that call back to the function
in `pricing.py`, where Read can inspect its implementation.

### Connect and advertise the tool

Connect with your starter's client when CODECRAFTERS_LSP_URL is set, and add
`lsp_tool.json` to your existing tools array. Without a connection, keep the
original tools.

Use your client's `call(action, payload)` equivalent to send these helper actions:

| Action        | What it does                                        |
| ------------- | --------------------------------------------------- |
| configuration | Returns the file-extension language map; pass `{}`  |
| notify        | Sends a method and params without a reply           |
| request       | Returns the server's result for a method and params |

For the test project:

```text
client.call("configuration", {})
-> {"extensionToLanguage": {".py": "python"}}
```

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
2. Open the URI once with the notify payload below, using the configuration map
   to set languageId.
3. Send the request payload below. Subtract one from both tool coordinates;
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
Cases cover multiple locations, null, errors, coordinates, and prompts without an
LSP connection.
