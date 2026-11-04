In this stage, you'll advertise the `LSP` tool to the model.

### Tell the model about LSP

Your agent now has an LSP client, but the model doesn't know that capability is
available. Just as you advertised Read in the base course, you'll describe LSP in
the `tools` array so the model knows when to call it and what arguments to send.

For example, the model will be able to ask where `invoice_total` in `checkout.py`
is defined. You'll implement that lookup in the next stage. Here, you'll register
the tool and add a temporary response so your agent can handle a call safely.

### Add the tool specification

Keep the client initialization from previous stages. If the factory returned a client,
add this specification to every model request's `tools` array alongside Read,
Write, and Bash. If LSP is unconfigured, keep using your existing tools without
LSP. All LSP course tests supply a connection.

Only `goToDefinition` is offered for now; a later stage adds reference lookup.

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Find where a symbol at a given file position is defined. Input line and character are one-based UTF-16; returned ranges are zero-based. Add 1 to each returned coordinate before reusing it as input.",
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

The model calls a tool named `LSP`. Its `operation` argument selects what to
do: for now, `goToDefinition`.

An LSP tool call can contain these arguments to look up the definition of
`invoice_total` at its call in `checkout.py`:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

The `filePath`, `line`, and `character` arguments identify the particular
occurrence of the symbol. A name alone isn't enough:
the same name can refer to different definitions in different files or scopes.

The tool accepts one-based positions: the first line and column are both 1.
Columns count UTF-16 code units, which match character counts for the ASCII text
in these exercises. Here, line 5, character 12 identifies the start of
`invoice_total`. You'll handle the server's position format in the next stage.

### Update your system prompt

The specification describes the tool's interface. Add this guidance to your
existing system prompt when LSP is configured to explain when the model should
use it:

```text
Use LSP to find where a symbol is defined. Tool positions are one-based UTF-16.
```

### Add a temporary LSP handler

The model can now return a tool call whose `function.name` is `LSP`. Your agent
already checks this field to decide whether to run Read, Write, or Bash. Extend
that check to recognize `LSP` too.

For now, respond with `LSP is not implemented yet` using your existing
tool-result flow. Set the response's `tool_call_id` to the incoming tool call's
`id`. This tells the model which call the response answers.

{{#lang_is_python}}

For a tool call stored in `call`, the new case can look like this:

```python
if call.function.name == "LSP":
    messages.append({
        "role": "tool",
        "tool_call_id": call.id,
        "content": "LSP is not implemented yet"
    })
```

{{/lang_is_python}}

Then continue the agent loop. This placeholder does not contact the language
server. In the next stage, you'll replace it with a definition lookup.

### Tests

The tester supplies the invoice project and runs:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. If navigation is not implemented yet, report the tool response without retrying."
```

The tester checks that every model request advertises `LSP` and that the tool
response reaches the model with the matching `tool_call_id`. The placeholder
response is sufficient.

The model can now request the LSP tool, and your agent can respond to that
request. Next, you'll replace the placeholder with a real definition lookup.
