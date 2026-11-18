In this stage, you'll replace the `LSP` tool's placeholder with a
`goToDefinition` lookup. The model will get the location of a function's
definition so it can read the implementation before changing it.

### Follow the imported function

In the [invoice project][example] introduced in the previous stage,
`checkout.py` imports `pricing.total` as `invoice_total`. Definition lookup
follows that import to `pricing.py`. The unrelated `total` functions in
`discounts.py` and `preview.py` should stay out of the result.

### Expected tool result

For a `goToDefinition` call on `checkout.py` at line 5, character 12, the tool
result must identify `pricing.py` at line 1, character 5. Return a path relative
to the agent's working directory and a one-based position, for example:

```text
Defined in pricing.py:1:5
```

The result must reach the model through the existing tool-result flow with the
matching `tool_call_id`. The agent continues its conversation, allowing the
model to retrieve the implementation with Read.

### Opening source documents

The server keeps its own copy of the documents your agent opens. Before a
file's first lookup, send its complete contents in a `textDocument/didOpen`
notification. A notification tells the server something without asking for a
reply. Use the client's `notify` action to send it.

Track which documents you've opened on this connection. The server rejects a
second `didOpen` for the same document. Mark it open only after the notification
succeeds, then reuse that state for later lookups.

LSP identifies documents by absolute file URIs, which begin with `file://`.
Resolve relative paths against the agent's working directory and encode
special characters. For example, `/project/cart notes.py` becomes
`file:///project/cart%20notes.py`. A document's initial version is 1.
Its `languageId` comes from the client's configured extension-to-language
mapping. In this project, `.py` maps to `python`.

A notification payload looks like this:

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

Here, `/project` stands for the agent's actual working directory, and the `text`
field must contain the complete file contents. Send this notification before
the definition request.

### Definition requests and positions

The model's `goToDefinition` call becomes a `textDocument/definition` request.
Use the client's `request` action because this message expects a result.
It uses the same URI as `didOpen`, but positions count from zero:

| Position | Line | Character |
| --- | --- | --- |
| Model's tool input | 5 | 12 |
| Language-server request | 4 | 11 |

Both interfaces measure the character offset in UTF-16 code units. An ASCII
character occupies one unit, while a character such as `😀` occupies two. A
Python string index counts Unicode code points, so it can differ from this
offset. The model's input already uses UTF-16 units: subtract one from each
coordinate when sending it to the server, and add one to each returned start
coordinate for the model.

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

For this lookup, the server returns:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

The range covers the name `total` in its definition, starting at the `t` and
ending just after the name. Its start position, 0:4, becomes the one-based 1:5
in your tool result.

### Supplied client API

The client's `call` method takes an action (`notify` or `request`) and a payload.
Read its definition in your supplied `lsp_client` file for the exact argument
and return types. The language mapping is exposed as `extension_to_language`,
`extensionToLanguage`, or `ExtensionToLanguage`, depending on your language.
Include the dot when looking up an extension, such as `.py`.

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Read the returned implementation and explain which total is called; preview.total is unrelated."
<the model's explanation that checkout calls pricing.total>
```

The tester will verify that:

- Your program sends `textDocument/didOpen` for `checkout.py`, then `textDocument/definition` at position 4:11
- The tool result for that call names `pricing.py` at line 1, character 5, with the matching `tool_call_id`
- Read returns the complete contents of `pricing.py` to the model
- Your program exits with code `0`

### Notes

- The LSP tool's path argument is `filePath`. The existing `Read` tool uses `file_path`.
- Await asynchronous client calls so the opening notification completes before the request.
- A definition lookup can also return several locations, no location, or a server error. We won't deal with those in this extension.
- The protocol defines [positions][position], [document opening][did-open], and [definition requests][definition].

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
