In this stage, you'll implement `goToDefinition`, which tells the model where a function is defined.

### Why look up a definition?

A call may use an imported alias rather than the function's original name. In
the [invoice project][example], `invoice_total` in `checkout.py` calls
`pricing.total`. Definition lookup follows that relationship so the model can
use Read to inspect the right implementation.

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

Before a file's first lookup, the language server needs its contents in a
`textDocument/didOpen` notification. The server remembers the document for the
connection; a second `didOpen` for the same URI is rejected.

LSP identifies documents by absolute file URIs. Resolve relative paths against
the agent's working directory and encode special characters: `/project/cart notes.py`
becomes `file:///project/cart%20notes.py`. A document's initial version is 1.
Its `languageId` comes from the client's configured extension-to-language
mapping; `.py` maps to `python` in this project.

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


A notification tells the server something without expecting an LSP reply. The
client sends it with the `notify` action. The server must receive `didOpen`
before the definition request, and a failed notification doesn't mark the
file as open.

### Definition requests and positions

The model's `goToDefinition` call corresponds to a `textDocument/definition`
request, sent through the client's `request` action. It uses the same URI as
`didOpen`, but positions count from zero:

| Position | Line | Character |
| --- | --- | --- |
| Model's tool input | 5 | 12 |
| Language-server request | 4 | 11 |

Both interfaces count columns in UTF-16 code units.

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

### Hint: tracking open documents

A set of opened URIs can help ensure that each document is opened only once.
Its state needs to survive across tool calls in the same run.

### Hint: using the supplied client

The client's `call` method takes an action (`notify` or `request`) and a payload.
Read its definition in your supplied `lsp_client` file for the exact argument
and return types. The language mapping is exposed as `extension_to_language`,
`extensionToLanguage`, or `ExtensionToLanguage`, depending on your language.
Include the dot when looking up an extension, such as `.py`.

### Notes

- The LSP tool's path argument is `filePath`, not `file_path` as in Read.
- Await asynchronous client calls so the opening notification completes before the request.
- A definition lookup can also return several locations, no location, or a server error. We won't deal with those in this extension.
- The protocol defines [positions][position], [document opening][did-open], and [definition requests][definition].

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
