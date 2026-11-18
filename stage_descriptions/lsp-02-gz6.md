Your `LSP` tool can now receive a model's request. In this stage, you'll replace
its placeholder result with `goToDefinition`, which tells the model where a
function is defined.

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

LSP calls a source file a document. Opening a document gives the server a copy
of its text to analyze. Your `Read` tool alone doesn't open it in the server.
Before a file's first lookup in this extension, send its complete contents in a
`textDocument/didOpen` notification. The server keeps that copy for the
connection, and rejects a second `didOpen` for the same document.

LSP identifies documents with a URI (Uniform Resource Identifier). For a local
file, this is an absolute path with a `file://` prefix. Resolve relative paths
against the agent's working directory and encode special characters: `/project/cart notes.py`
becomes `file:///project/cart%20notes.py`.

The document's version number identifies the copy of the text you've sent.
Start at version 1. Its `languageId` tells the server which programming language
to analyze. Use the client's configured extension-to-language mapping, where
`.py` maps to `python` in this project.

A notification sends information without expecting an LSP response. Use the
client's `notify` action with this payload:

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

The opening notification must complete before the definition request. A failed
notification doesn't mark the file as open.

### Definition requests and positions

A request asks the server for a result. The model's `goToDefinition` call maps
to a `textDocument/definition` request, sent through the client's `request`
action. It uses the same URI as `didOpen`, but positions count from zero:

| Position | Line | Character |
| --- | --- | --- |
| Model's tool input | 5 | 12 |
| Language-server request | 4 | 11 |

Both interfaces count columns in UTF-16 code units. Only the starting index
changes between the model's tool call and the server request.

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

Use the client initialized in earlier stages to send the payloads above.
The helper handles message delivery and request IDs. Your agent supplies the
document information and returns the resulting location to the model.

{{#lang_is_c}}
The call is `lsp_call(action, json)`, with a JSON string as its payload. It
returns an allocated JSON string on success, which you must free after use.
`NULL` indicates an error, available through `lsp_last_error()`. The language
mapping is `lsp.extension_to_language`, a cJSON object.
{{/lang_is_c}}
{{#lang_is_cpp}}
The call is `lsp.call(action, payload)`, with a `nlohmann::json` payload and
result. The language mapping is `lsp.extension_to_language`.
{{/lang_is_cpp}}
{{#lang_is_csharp}}
The call is `await lsp.Call(action, json)`, with a JSON string as its payload
and result. The language mapping is `lsp.ExtensionToLanguage`.
{{/lang_is_csharp}}
{{#lang_is_go}}
The call is `lsp.Call(action, payload)`. It encodes the payload as JSON and
returns a `json.RawMessage` and an error. The language mapping is
`lsp.ExtensionToLanguage`.
{{/lang_is_go}}
{{#lang_is_java}}
The call is `lsp.call(action, json)`, with a JSON string as its payload and
result. It can throw checked exceptions. The language mapping is
`lsp.extensionToLanguage`.
{{/lang_is_java}}
{{#lang_is_javascript}}
The call is `await lsp.call(action, payload)`, with a JSON-compatible object as
its payload and a decoded JSON result. The language mapping is
`lsp.extensionToLanguage`.
{{/lang_is_javascript}}
{{#lang_is_python}}
The call is `lsp.call(action, payload)`, with a dictionary as its payload and a
decoded JSON result. The language mapping is `lsp.extension_to_language`.
{{/lang_is_python}}
{{#lang_is_rust}}
The call is `lsp.call(action, &payload)`, with a `serde_json::Value` payload.
It returns a `Result` containing a `serde_json::Value`. The language mapping is
`lsp.extension_to_language`.
{{/lang_is_rust}}
{{#lang_is_typescript}}
The call is `await lsp.call(action, payload)`, with a JSON-compatible object as
its payload. The decoded JSON result has type `unknown`. The language mapping
is `lsp.extensionToLanguage`.
{{/lang_is_typescript}}
{{#lang_is_zig}}
The call is `lsp.call(action, json)`, with a JSON string as its payload. It
returns an error union containing allocated JSON bytes, which you must free
with the client's allocator after use. The language mapping is
`lsp.extension_to_language`.
{{/lang_is_zig}}

Here, `lsp` is your initialized client. Include the dot when looking up an
extension, such as `.py`. The `notify` action returns JSON `null` after sending
the notification. The `request` action returns the server's result, such as the
location shown above.

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

- The LSP tool's path argument is `filePath`. Read continues to use `file_path`.
- Await asynchronous client calls so the opening notification completes before the request.
- A definition lookup can also return several locations, no location, or a server error. We won't deal with those in this extension. The protocol defines [positions][position], [document opening][did-open], and [definition requests][definition].

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
