In this stage, you'll add support for the `hover` operation.

### Looking up types and documentation

Before calling or changing a function, your agent may need to know what types
its parameters accept and what it returns. A **hover** query asks the language
server for type information and documentation at a position in a file, just as
hovering over code in an editor does.

Your program has a connection to the server. Now you'll make it available to the
model through an `LSP` tool with a `hover` operation. Returning the server's
answer as a tool result lets the model use that information in its next step.

### The `hover` operation

The corresponding LSP request is
[`textDocument/hover`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_hover).

Add this specification to your request's `tools` array, just as you did for
`Read`:

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Returns language-server information about a symbol at a one-based line and UTF-16 character offset.",
    "parameters": {
      "type": "object",
      "properties": {
        "operation": { "type": "string", "enum": ["hover"] },
        "filePath": { "type": "string" },
        "line": { "type": "integer", "minimum": 1 },
        "character": { "type": "integer", "minimum": 1 }
      },
      "required": ["operation", "filePath", "line", "character"]
    }
  }
}
```

### Opening a document

When the model calls the tool, the server needs a copy of the file before it can
answer. Read the file and send
[`textDocument/didOpen`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen):

```json
{
  "jsonrpc": "2.0",
  "method": "textDocument/didOpen",
  "params": {
    "textDocument": {
      "uri": "file:///path/to/project/pricing.py",
      "languageId": "python",
      "version": 1,
      "text": "def total(price: int, quantity: int) -> int:\n    return price * quantity\n"
    }
  }
}
```

Use the language ID from `.lsp.json`'s `extensionToLanguage` map and put the
complete file contents in `text`. The `uri` is the file's absolute path written
as a file URI. Use your language's URI utilities so paths with spaces are
encoded correctly. Open each URI only once.

Then send a request with a fresh ID:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "textDocument/hover",
  "params": {
    "textDocument": { "uri": "file:///path/to/project/pricing.py" },
    "position": { "line": 0, "character": 4 }
  }
}
```

Append the response's `result` to `messages` as a tool result and continue your
agent loop. You can return it as JSON text. A `null` result means no hover
information is available. If the server returns a protocol error, pass that back
as a tool error.

### Tests

The tester will create `pricing.py`, configure its server, and run:

```bash
$ ./your_program.sh -p "Use LSP hover on pricing.py at line 1, character 5. Report its documentation word."
```

For example, the server's hover result can be:

```json
{ "contents": { "kind": "plaintext", "value": "Documentation word: orchard" } }
```

The tester checks that your program requests the right position and passes the
returned word back to the model. The word is random at test time and isn't in
the project files. Other cases include null results, protocol errors, repeated
queries, and paths with spaces.

### Notes

- Tool positions start at `1`, as in Claude Code. Subtract `1` from both
  coordinates for the LSP request, whose positions start at `0`. Columns count
  UTF-16 code units, so some characters occupy two units.
- The server supports `hoverProvider` and document opening. Closing documents
  before a graceful shutdown is supported, but not required by this stage.
- The LSP request ID and the model's tool-call ID are separate. Use the model's
  ID for `tool_call_id` when appending the tool result to `messages`.
