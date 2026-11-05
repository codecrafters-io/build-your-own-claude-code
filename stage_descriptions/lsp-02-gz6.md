In this stage, you'll implement `goToDefinition`, which tells the model where a function is defined.

### Why look up a definition?

Your LSP handler currently returns a placeholder. Now it will ask the language
server where a symbol is defined. In the [invoice project][example],
`invoice_total` in `checkout.py` resolves to `pricing.total`. With that location,
the model can open `pricing.py` with Read and explain what the function does.

### 1. Prepare the source document

Parse the arguments to extract the `filePath`, `line`, and `character`. Before
the first lookup on a file, the language server needs three things about it:

1. Read the file at `filePath`, the same way your Read tool does.
2. Convert its absolute path to a file URI, such as
   `file:///project/checkout.py`. The examples below call this `uri`.
3. Look up its language. Your LSP client stored a mapping from file extensions
   to language IDs when it started, as its `extension_to_language` field
   (`extensionToLanguage` or `ExtensionToLanguage`, depending on your language's
   naming style). For the invoice project it's `{".py": "python"}`. Look up the
   file's extension, including the dot: `checkout.py` gives `python`, regardless
   of the language your agent is written in. The examples below call this
   `languageId`.

### 2. Track and open documents

Before you look up a symbol in a file, the language server needs that file's
contents. You send them once, in a [`textDocument/didOpen`][did-open]
notification, and the server remembers them.

So keep track of which files you've opened, using a set of URIs that lasts for
the whole run, not one tool call. Before each lookup, send `didOpen` only if the
file's URI isn't in the set yet, then add it. The server rejects a second
`didOpen` for the same file.

In your LSP handler, build this `didOpen` object from the `uri`, `languageId`,
and file contents you prepared in the previous step. Version 1 marks the file's
first contents:

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

Send it with your LSP client's `call` method. `call` takes an action name and a
message, here `"notify"` and the object above. In LSP, a *notification* tells
the server something without expecting a reply, and `didOpen` is one. In the
next step, you'll use the `request` action for a message the server does answer.

### 3. Request the definition

In your LSP handler, right after the `didOpen` check, turn the model's
`goToDefinition` call into a [`textDocument/definition`][definition] request to
the language server, using the same `uri`. Subtract one from the tool's `line`
and `character`. For example, line 5, character 12 becomes the zero-based LSP
[position][position] 4:11. Both interfaces count columns in UTF-16 code units.

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

Send it with your LSP client's `call` method. `call` takes an action name and a
message, here `"request"` and the object above, and returns the server's result.
Read `call`'s definition in your `lsp_client` file for the exact argument and
return types.

### 4. Return the location to the model

For `invoice_total` in `checkout.py`, the server returns this location:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

The URI points to `pricing.py`. The range covers the name `total` in its
definition, starting at the `t` and ending just after the name. Like the
position you sent, it counts from zero.

The model counts from one, and it reuses the location you return as input to
later LSP calls. So return it as text, the way Claude Code does: the path
relative to your agent's working directory, then the start line and character,
each plus one:

```text
Defined in pricing.py:1:5
```

Put that text in a tool message's `content` field, and set `tool_call_id` to
the ID of the model's LSP call. Then continue the agent loop.

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Read the returned implementation and explain which total is called; preview.total is unrelated."
<the model's explanation that checkout calls pricing.total>
```

When your program passes, the tester prints:

```text
[tester::#GZ6] Resolved invoice_total to pricing.total; preview.total is unrelated
[tester::#GZ6] Case resolve-and-read-implementation passed protocol, tool-result and file checks
```

The tester will verify that:

- Your program sends `textDocument/didOpen` for `checkout.py`, then `textDocument/definition` at position 4:11
- The tool result for that call names `pricing.py` at line 1, character 5, with the matching `tool_call_id`
- Read returns the complete contents of `pricing.py` to the model
- Your program exits with code `0`

### Notes

- The LSP tool's path argument is `filePath`, not `file_path` as in Read.
- We recommend URL encoding file paths when you convert them to URIs, so `cart notes.py` becomes `cart%20notes.py`.
- A definition lookup can also return several locations, no location, or a server error. We won't deal with those in this extension.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
