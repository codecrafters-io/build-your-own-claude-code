In this stage, you'll advertise the `LSP` tool to the model.

### Make navigation available to the model

Your agent now has an LSP client, but the model doesn't know that capability is
available. Just as you advertised Read in the base course, you'll describe LSP in
the `tools` array so the model knows when to call it and what arguments to send.

For example, the model will be able to ask where `invoice_total` in `checkout.py`
is defined. You'll implement that lookup in the next stage. Here, you'll register
the tool and add a temporary response so your agent can handle a call safely.

### Add the tool specification

Keep the client and configuration call from Stage 1. Add this specification to
every model request's `tools` array alongside Read, Write, and Bash. Only
`goToDefinition` is offered for now; a later stage adds reference lookup.

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Returns raw language-server results with file URIs and zero-based UTF-16 ranges.",
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

The operation selects the question to ask. `filePath`, `line`, and `character`
identify the occurrence of the symbol the model wants to investigate.

The tool accepts one-based positions: the first line and column are both 1.
Columns count UTF-16 code units, which match character counts for the ASCII text
in these exercises. The server's results use zero-based positions. You'll handle
that conversion when you implement definition lookup.

### Update your system prompt

The specification describes the tool's interface. Add this guidance to your
existing system prompt to explain when the model should use it:

```text
Use LSP for code navigation. Tool positions are one-based UTF-16.
Edit files with Write so the language server sees changes.
```

The Write guidance prepares for Stage 5, where you'll send edited contents to
the server from your Write handler. Bash edits won't pass through that handler
and can leave the server's view of a file outdated.

### Add a temporary LSP handler

Advertising a tool makes it available immediately, even before you've implemented
navigation. If the model calls LSP, return a tool message with content
`LSP is not implemented yet` and the matching `tool_call_id`. This lets the
agent loop continue instead of crashing.

{{#lang_is_python}}

For a tool call stored in `call`, the message is:

```python
{"role": "tool", "tool_call_id": call.id, "content": "LSP is not implemented yet"}
```

{{/lang_is_python}}

In the next stage, you'll replace this temporary response with a definition
lookup. You don't need document messages or navigation requests in this stage.

### Tests

The tester runs the same Read-only prompt as Stage 1:

```bash
$ ./your_program.sh -p "Use only Read to inspect checkout.py and pricing.py. Explain how checkout uses the pricing function."
```

Your agent must still call `configuration` before its first model request. Every
model request must now include the supplied LSP specification, with
`goToDefinition` and all four required arguments. The existing Read results must
still preserve the complete contents of both files.

The prompt uses Read so you can verify tool advertisement before implementing
navigation. The temporary LSP handler may not run in this test. The model's final
explanation can vary.
