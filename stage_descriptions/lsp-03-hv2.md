In this stage, you'll add support for the `hover` operation.

### The `hover` operation

Your program can now communicate with the server, but the model has no way to
use it yet. You'll add an `LSP` tool with a `hover` operation, which returns the
type information and documentation you'd see when hovering in an editor.

The corresponding LSP request is
[`textDocument/hover`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_hover).

Add this specification to your request's `tools` array, just as you did for
`Read`:

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Returns language-server information about a symbol at a zero-based line and UTF-16 character offset.",
    "parameters": {
      "type": "object",
      "properties": {
        "operation": { "type": "string", "enum": ["hover"] },
        "file_path": { "type": "string" },
        "line": { "type": "integer", "minimum": 0 },
        "character": { "type": "integer", "minimum": 0 }
      },
      "required": ["operation", "file_path", "line", "character"]
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

Use `languageId` from `.lsp.json` and put the complete file contents in `text`.
The `uri` is the file's absolute path written as a file URI. Use your language's
URI utilities so paths with spaces are encoded correctly. Open each URI only
once.

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
$ ./your_program.sh -p "Use LSP hover on pricing.py at line 0, character 4. Report its documentation word."
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

- The first line is line `0`. For ASCII text, a character's index equals its
  UTF-16 offset.
- The server supports `hoverProvider` and document opening. Send
  `textDocument/didClose` for open documents before shutdown.
- The LSP request ID and the model's tool-call ID are separate. Use the model's
  ID for `tool_call_id` when appending the tool result to `messages`.
