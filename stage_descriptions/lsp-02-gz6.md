In this stage, you'll replace the `goToDefinition` placeholder with the file and
position of the function's definition.

### Why look up a definition?

A call may use an imported alias rather than the function's original name. In
the invoice project, `invoice_total` in [checkout.py][checkout] calls
[pricing.total][pricing]. Definition lookup follows that relationship so the
model can use Read to inspect the right implementation.

### Expected tool result

For a `goToDefinition` call on `checkout.py` at line 5, character 12, the tool
result must identify `pricing.py` at line 1, character 5. Return a path relative
to the agent's working directory and a one-based position, for example:

```text
Defined in pricing.py:1:5
```

The result must reach the model through the existing tool-result flow with the
matching `tool_call_id`. Make sure the tool description also says that returned
positions are one-based. If you reused `lsp_tool.json`, replace its older
zero-based-result description. The agent continues its conversation, allowing
the model to retrieve the implementation with Read.

### Use the supplied client

The client is already initialized. The payloads below contain a `method` and its
`params`. The client also stores a mapping from file extensions to language IDs.
Send payloads with one of two client actions:

- `notify` sends a notification without expecting an LSP reply.
- `request` waits for a reply and returns the server's result.

{{#lang_is_c}}

Use `lsp_call(action, json)` with a JSON string. It returns an allocated JSON
string, which you must free after reading. Check for `NULL` before parsing. A
successful notification returns the JSON text `null`. The language mapping is
the `cJSON` object `lsp.extension_to_language`.

{{/lang_is_c}}

{{#lang_is_cpp}}

Use `lsp.call(action, payload)` with a `nlohmann::json` value. It returns a
`nlohmann::json` value and throws on failure. The language mapping is
`lsp.extension_to_language`.

{{/lang_is_cpp}}

{{#lang_is_csharp}}

Use `await lsp.Call(action, json)` with a JSON string. It returns a JSON string
and throws on failure. The language mapping is `lsp.ExtensionToLanguage`.

{{/lang_is_csharp}}

{{#lang_is_go}}

Use `lsp.Call(action, payload)` with a JSON-encodable value. It returns
`json.RawMessage` and an error. Check the error before decoding the result. The
language mapping is `lsp.ExtensionToLanguage`.

{{/lang_is_go}}

{{#lang_is_java}}

Use `lsp.call(action, json)` with a JSON string. It returns a JSON string and
can throw checked exceptions. The language mapping is `lsp.extensionToLanguage`.

{{/lang_is_java}}

{{#lang_is_javascript}}

Use `await lsp.call(action, payload)` with a JSON-serializable value. It returns
the decoded JSON result and rejects on failure. The language mapping is
`lsp.extensionToLanguage`.

{{/lang_is_javascript}}

{{#lang_is_python}}

Use `lsp.call(action, payload)` with a JSON-serializable value. It returns the
decoded JSON result and raises an exception on failure. The language mapping is
`lsp.extension_to_language`.

{{/lang_is_python}}

{{#lang_is_rust}}

Use `lsp.call(action, &payload)` with a `serde_json::Value`. It returns a
`Result<Value, Box<dyn Error>>`. Check for an error before using the JSON value.
The language mapping is `lsp.extension_to_language`.

{{/lang_is_rust}}

{{#lang_is_typescript}}

Use `await lsp.call(action, payload)` with a JSON-serializable value. It returns
the decoded JSON result as `unknown` and rejects on failure. Await the call and
check the result's shape before using it. The language mapping is
`lsp.extensionToLanguage`.

{{/lang_is_typescript}}

{{#lang_is_zig}}

Use `lsp.call(action, json)` on a mutable client with serialized JSON bytes. It
returns an error union containing allocated JSON bytes. Handle the error before
parsing and free a successful result with the client's allocator when finished.
The language mapping is `lsp.extension_to_language`.

{{/lang_is_zig}}

Here, `lsp` refers to the client initialized in the previous stage. The client
handles message delivery. Your task is to construct the document and lookup
payloads and turn the lookup result into a model-facing tool result.

### Opening source documents

Before a file's first lookup, the language server needs its contents in a
`textDocument/didOpen` notification. The server remembers the document for the
connection. The test server rejects a second `didOpen` for the same URI.

LSP identifies documents by absolute file URIs. Resolve relative paths against
the agent's working directory and encode special characters:
`/project/cart notes.py` becomes `file:///project/cart%20notes.py`. A document's
initial version is 1. Its `languageId` comes from the client's configured
extension-to-language mapping. Include the dot when looking up an extension. In
this project, `.py` maps to `python`.

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

Send this payload with the `notify` action before the definition request. Record
the file as open only after the client call succeeds.

### Definition requests and positions

The model's `goToDefinition` call corresponds to a `textDocument/definition`
request, sent through the client's `request` action. It uses the same URI as
`didOpen`, but positions count from zero:

| Position                | Line | Character |
| ----------------------- | ---- | --------- |
| Model's tool input      | 5    | 12        |
| Language-server request | 4    | 11        |

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
in your tool result. Decode the returned file URI into a path, then make that
path relative to the agent's working directory.

### Tests

The tester will create the invoice project and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Read the returned implementation and explain which total is called; preview.total is unrelated."
<the model's explanation that checkout calls pricing.total>
```

The tester will verify that:

- Your program sends `textDocument/didOpen` for `checkout.py`, then
  `textDocument/definition` at position 4:11
- The tool result for that call names `pricing.py` at line 1, character 5, with
  the matching `tool_call_id`
- Read returns the complete contents of `pricing.py` to the model
- Your program exits with code `0`

### Notes

- The LSP tool's path argument is `filePath`. Read uses `file_path`.
- Await asynchronous client calls so the opening notification completes before
  the request.
- A definition lookup can also return several locations, no location, or a
  server error. We won't deal with those in this extension.
- The protocol defines [positions][position], [document opening][did-open], and
  [definition requests][definition].

[position]:
  https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]:
  https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]:
  https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
[checkout]:
  https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_designs/lsp_exercise/checkout.py
[pricing]:
  https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_designs/lsp_exercise/pricing.py
