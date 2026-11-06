In the previous stage, your LSP handler returned a placeholder. Now you'll
implement `goToDefinition` to return a definition location from the language server.

### Definition lookup

In the invoice project, `invoice_total` in `checkout.py` resolves to
`pricing.total`. The model identifies the call with these tool arguments:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

The tool call and the language-server request use different names:

| Name | Role |
| --- | --- |
| `LSP` | The tool the model calls. |
| `goToDefinition` | The operation in that tool call's arguments. |
| `textDocument/definition` | The request sent to the language server. |

### Source documents

Before a file's first lookup, the server needs its contents in a
[`textDocument/didOpen` notification][did-open]. Each file URI must be opened
only once per connection, even if the model looks up several symbols in it.

Resolve relative paths against the agent's working directory, which the tester
sets to the invoice project. LSP identifies files by absolute file URIs with
special characters encoded: `/project/cart notes.py` becomes
`file:///project/cart%20notes.py`.

A `didOpen` payload looks like this:

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

Send notifications through the supplied client's `notify` action. The server
must receive `didOpen` before the definition request. A failed notification
doesn't mark the file as open.

The client exposes an extension-to-language mapping fetched during
initialization. Use it to determine `languageId`. The invoice project is Python
regardless of your agent's implementation language, so `.py` maps to `python`.
Version 1 identifies the initial contents; a later stage adds edit synchronization.

### Definition requests

Send a [`textDocument/definition` request][definition] through the client's
`request` action with this payload:

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

The URI must identify the same document that was opened. LSP [positions][position]
are zero-based, while your tool inputs are one-based: tool line 5, character 12
becomes LSP line 4, character 11. Both count columns in UTF-16 code units.

### Returning locations

For the call in `checkout.py`, the server can return this definition location:

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
definition, starting at the `t` and ending just after the name.

Return the server's result as JSON text in a tool message with the matching
`tool_call_id`, then continue the agent loop. Preserve the URI and range
unchanged. Clients returning JSON text need no additional serialization.

The model can use Read to retrieve the code at the returned location. If it
reuses that location in another LSP call, it must convert the zero-based range
back to one-based tool inputs: `0:4` becomes `1:5`. The tool description from
the previous stage explains this conversion.

### Supplied client API

The calls below use `lsp` to refer to your initialized client. Each takes an
action (`notify` or `request`) and one of the payloads shown above.

{{#lang_is_c}}
The language mapping is `lsp.extension_to_language`, a cJSON object.
`lsp_call(action, json)` takes serialized JSON and returns allocated JSON text.
Free the returned text after use.
{{/lang_is_c}}

{{#lang_is_cpp}}
The language mapping is `lsp.extension_to_language`.
`lsp.call(action, payload)` takes and returns nlohmann JSON values. The factory
returns an optional client; access its value when configured.
{{/lang_is_cpp}}

{{#lang_is_csharp}}
The language mapping is `lsp.ExtensionToLanguage`.
`await lsp.Call(action, json)` takes serialized JSON and returns JSON text.
{{/lang_is_csharp}}

{{#lang_is_go}}
The language mapping is `lsp.ExtensionToLanguage`.
`lsp.Call(action, payload)` accepts a JSON-serializable value and returns
`(json.RawMessage, error)`. A successful result already contains JSON text.
{{/lang_is_go}}

{{#lang_is_java}}
The language mapping is `lsp.extensionToLanguage`.
`lsp.call(action, json)` takes serialized JSON and returns JSON text.
Jackson is included by the starter.
{{/lang_is_java}}

{{#lang_is_javascript}}
The language mapping is `lsp.extensionToLanguage`.
`await lsp.call(action, payload)` takes and returns JavaScript values.
{{/lang_is_javascript}}

{{#lang_is_python}}
The language mapping is `lsp.extension_to_language`.
`lsp.call(action, payload)` takes and returns Python values. Use the standard
`json` module to serialize the result for a tool message.
{{/lang_is_python}}

{{#lang_is_rust}}
The language mapping is `lsp.extension_to_language`.
`lsp.call(action, &payload)` takes a `serde_json::Value` by reference and returns
a `Result<Value, Box<dyn Error>>`. The factory returns an optional client;
access its value when configured.
{{/lang_is_rust}}

{{#lang_is_typescript}}
The language mapping is `lsp.extensionToLanguage`.
`await lsp.call(action, payload)` takes a value and returns `unknown`.
The client can be `null` when unconfigured.
{{/lang_is_typescript}}

{{#lang_is_zig}}
The language mapping is `lsp.extension_to_language`, a `std.json.ObjectMap`.
`try lsp.call(action, json)` takes serialized JSON and returns allocated JSON
text. Free responses after use, including notification acknowledgements. A tool
message must own its content before that response is freed. The factory returns
an optional client; access its value when configured.
{{/lang_is_zig}}

### Tests

The tester supplies the invoice project and runs:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Read the returned implementation and explain which total is called; preview.total is unrelated."
```

The tester checks that the LSP response identifies `total` in `pricing.py` and
reaches the model with the matching call ID. The model must then use Read to
retrieve the implementation from `pricing.py`.

This stage covers one successful lookup with a single definition location.
Multiple definitions, missing definitions, and server-error responses aren't
required here.

Next, you'll find where that function is used.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
