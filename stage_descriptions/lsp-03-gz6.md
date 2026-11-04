In Stage 2, your LSP handler returned a placeholder. Now you'll implement
`goToDefinition` to return a definition location from the language server.
Keep Stage 1's client, your tool specification, and your existing tool-result flow.

### Why look up a definition?

`checkout.py` imports the `total` function from `pricing.py` as `invoice_total`,
then calls it using that alias:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

Definition lookup asks where `invoice_total` in the return statement is defined.
The server resolves the alias to `pricing.total` and returns its location in
`pricing.py`. The model can then use Read to inspect that file. The unrelated
`preview.total` has the same function name but isn't the target of checkout's import.

In your existing `LSP` branch, parse the tool call's `function.arguments` as JSON
to obtain `operation`, `filePath`, `line`, and `character`. The arguments look
like this:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

Line 5, character 12 identifies the first character of `invoice_total` in
`checkout.py`'s return statement.

The examples below use the initialized client as `lsp` inside your LSP handler.

{{#lang_is_cpp}}
Check `if (lsp_client)` and bind `auto& lsp = *lsp_client;` in that branch.
{{/lang_is_cpp}}
{{#lang_is_rust}}
Use `if let Some(lsp) = lsp_client.as_ref()` to access it in that branch.
{{/lang_is_rust}}
{{#lang_is_zig}}
Use `if (lsp_client) |*lsp|` to access it in that branch.
{{/lang_is_zig}}
{{#lang_is_typescript}}
Check `if (lsp)` in that branch so TypeScript narrows it to `LSPClient`.
{{/lang_is_typescript}}
{{#lang_is_csharp}}
Check `if (lsp is not null)` in that branch to access the initialized client.
{{/lang_is_csharp}}

The names describe different parts of this lookup:

| Name | Role |
| --- | --- |
| `LSP` | The tool the model calls. |
| `goToDefinition` | The operation in that tool call's arguments. |
| `textDocument/definition` | The request your handler sends to the language server. |

### 1. Prepare the source document

Your LSP handler reads the source file and sends its contents to the language
server before that file's first lookup. This gives the server the code to
analyze. Later, the model uses the Read tool to inspect the implementation at
the returned location.

Load `filePath` using your existing path resolution and UTF-8 reading code.
Resolve relative paths against the agent's working directory, which the tester
sets to the invoice project. Convert the absolute path to a file URI, encoding
special characters: `/project/cart notes.py` becomes
`file:///project/cart%20notes.py`. Use this resolved URI as `uri` in the examples
below.

The server also needs to know the file's language. During initialization, the
client fetched and stored a mapping from file extensions to language IDs. The
course's invoice project is Python regardless of your agent's implementation
language, so the mapping is:

```json
{ ".py": "python" }
```

{{#lang_is_c}}
Read this mapping from `lsp.extension_to_language`, a cJSON object.
{{/lang_is_c}}
{{#lang_is_cpp}}
Read this mapping from `lsp.extension_to_language`, a JSON object.
{{/lang_is_cpp}}
{{#lang_is_csharp}}
Read this mapping from `lsp.ExtensionToLanguage`, a dictionary.
{{/lang_is_csharp}}
{{#lang_is_go}}
Read this mapping from `lsp.ExtensionToLanguage`, a `map[string]string`.
{{/lang_is_go}}
{{#lang_is_java}}
Read this mapping from `lsp.extensionToLanguage`, a `Map<String, String>`.
{{/lang_is_java}}
{{#lang_is_javascript}}
Read this mapping from `lsp.extensionToLanguage`, an object.
{{/lang_is_javascript}}
{{#lang_is_python}}
Read this mapping from `lsp.extension_to_language`, a dict.
{{/lang_is_python}}
{{#lang_is_rust}}
Read this mapping from `lsp.extension_to_language`, a `HashMap<String, String>`.
{{/lang_is_rust}}
{{#lang_is_typescript}}
Read this mapping from `lsp.extensionToLanguage`, a `Record<string, string>`.
{{/lang_is_typescript}}
{{#lang_is_zig}}
Read this mapping from `lsp.extension_to_language`, a `std.json.ObjectMap`.
{{/lang_is_zig}}

Look up the queried file's extension in this mapping and use the returned value
as `languageId`. For `checkout.py`, `.py` maps to `python`.

### 2. Track and open documents

The server keeps the contents sent in a `textDocument/didOpen` notification.
Send it before the first lookup for a file. Keep a set of opened URIs so later
lookups for the same file skip `didOpen`.

Initialize this set once beside the client, outside the agent loop:

{{#lang_is_python}}

```python
opened_uris = set()
```

{{/lang_is_python}}

{{#lang_is_javascript}}

```javascript
const openedUris = new Set();
```

{{/lang_is_javascript}}

{{#lang_is_typescript}}

```typescript
const openedUris = new Set<string>();
```

{{/lang_is_typescript}}

{{#lang_is_go}}

```go
openedURIs := make(map[string]bool)
```

{{/lang_is_go}}

{{#lang_is_java}}

```java
var openedUris = new java.util.HashSet<String>();
```

{{/lang_is_java}}

{{#lang_is_rust}}

```rust
let mut opened_uris = std::collections::HashSet::<String>::new();
```

{{/lang_is_rust}}

{{#lang_is_c}}

```c
cJSON *opened_uris = cJSON_CreateObject();
if (!opened_uris) exit(1);
```

Use the cJSON object as a set of URI keys. Call `cJSON_Delete(opened_uris)`
after the agent loop.

{{/lang_is_c}}

{{#lang_is_cpp}}

```cpp
std::unordered_set<std::string> opened_uris;
```

Add `#include <unordered_set>` to your imports.

{{/lang_is_cpp}}

{{#lang_is_csharp}}

```csharp
var openedUris = new HashSet<string>();
```

Use `System.Collections.Generic`.

{{/lang_is_csharp}}

{{#lang_is_zig}}

```zig
var opened_uris = std.StringHashMap(void).init(allocator);
defer {
    var keys = opened_uris.keyIterator();
    while (keys.next()) |key| allocator.free(key.*);
    opened_uris.deinit();
}
```

The set owns a copy of each URI string. The deferred cleanup frees those
strings and the set after the agent loop.

{{/lang_is_zig}}

In your LSP handler, build the following [`didOpen` object][did-open]. Replace
`uri` with the resolved file URI, `text` with the complete file contents, and
`languageId` with the mapped language ID.

{{#lang_is_python}}
Store this object as `open_payload`.
{{/lang_is_python}}
{{#lang_is_javascript}}
Store this object as `openPayload`.
{{/lang_is_javascript}}
{{#lang_is_typescript}}
Store this object as `openPayload`.
{{/lang_is_typescript}}
{{#lang_is_go}}
Store this object as `openPayload`.
{{/lang_is_go}}
{{#lang_is_java}}
Store this object as `openPayload`.
{{/lang_is_java}}
{{#lang_is_rust}}
Store this object as `open_payload`.
{{/lang_is_rust}}
{{#lang_is_c}}
Serialize this object as `open_json`.
{{/lang_is_c}}
{{#lang_is_cpp}}
Store this object as `open_payload`.
{{/lang_is_cpp}}
{{#lang_is_csharp}}
Store this object as `openPayload`.
{{/lang_is_csharp}}
{{#lang_is_zig}}
Serialize this object as `open_json`.
{{/lang_is_zig}}

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

Send this object through the client's `notify` action only if `uri` is absent
from the set. Add the URI after that call succeeds. The handler code in the next
section shows this order.

Version 1 identifies the file's initial contents. Stage 5 adds edit synchronization.

### 3. Request the definition

Build the following [`definition` object][definition] using the same `uri`.
Subtract one from the tool's `line` and `character`: line 5, character 12 becomes
zero-based LSP [position][position] 4:11. Both interfaces count columns in UTF-16
code units.

{{#lang_is_python}}
Store this object as `definition_payload`.
{{/lang_is_python}}
{{#lang_is_javascript}}
Store this object as `definitionPayload`.
{{/lang_is_javascript}}
{{#lang_is_typescript}}
Store this object as `definitionPayload`.
{{/lang_is_typescript}}
{{#lang_is_go}}
Store this object as `definitionPayload`.
{{/lang_is_go}}
{{#lang_is_java}}
Store this object as `definitionPayload`.
{{/lang_is_java}}
{{#lang_is_rust}}
Store this object as `definition_payload`.
{{/lang_is_rust}}
{{#lang_is_c}}
Serialize this object as `definition_json`.
{{/lang_is_c}}
{{#lang_is_cpp}}
Store this object as `definition_payload`.
{{/lang_is_cpp}}
{{#lang_is_csharp}}
Store this object as `definitionPayload`.
{{/lang_is_csharp}}
{{#lang_is_zig}}
Serialize this object as `definition_json`.
{{/lang_is_zig}}

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

Use the two payloads and the opened-URI set in your LSP handler. The `notify`
call sends the document contents; the `request` call asks for the definition:

{{#lang_is_python}}

```python
if uri not in opened_uris:
    lsp.call("notify", open_payload)
    opened_uris.add(uri)
result = lsp.call("request", definition_payload)
content = json.dumps(result)
```

Use the standard `json` module.

{{/lang_is_python}}

{{#lang_is_javascript}}

```javascript
if (!openedUris.has(uri)) {
  await lsp.call("notify", openPayload);
  openedUris.add(uri);
}
const result = await lsp.call("request", definitionPayload);
const content = JSON.stringify(result);
```

{{/lang_is_javascript}}

{{#lang_is_typescript}}

```typescript
if (!openedUris.has(uri)) {
  await lsp.call("notify", openPayload);
  openedUris.add(uri);
}
const result = await lsp.call("request", definitionPayload);
const content = JSON.stringify(result)!;
```

{{/lang_is_typescript}}

{{#lang_is_go}}

```go
if !openedURIs[uri] {
    if _, err := lsp.Call("notify", openPayload); err != nil {
        log.Fatal(err)
    }
    openedURIs[uri] = true
}
result, err := lsp.Call("request", definitionPayload)
if err != nil {
    log.Fatal(err)
}
content := string(result)
```

Use the `log` import from Stage 1. `result` already contains serialized JSON.

{{/lang_is_go}}

{{#lang_is_java}}

```java
var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
if (!openedUris.contains(uri)) {
    lsp.call("notify", mapper.writeValueAsString(openPayload));
    openedUris.add(uri);
}
String content = lsp.call("request", mapper.writeValueAsString(definitionPayload));
```

Jackson is included by the starter. Successful `lsp.call` results are JSON text.

{{/lang_is_java}}

{{#lang_is_rust}}

```rust
if !opened_uris.contains(&uri) {
    lsp.call("notify", &open_payload)?;
    opened_uris.insert(uri.clone());
}
let result = lsp.call("request", &definition_payload)?;
let content = result.to_string();
```

Use `?` in a function returning a compatible `Result`, as in Stage 1. Here,
`uri` is a `String`; cloning it gives the set its own copy.

{{/lang_is_rust}}

{{#lang_is_c}}

```c
if (!cJSON_HasObjectItem(opened_uris, uri)) {
    char *ack = lsp_call("notify", open_json);
    if (!ack) exit(1);
    free(ack);
    cJSON_AddBoolToObject(opened_uris, uri, 1);
}
char *content = lsp_call("request", definition_json);
if (!content) exit(1);
```

The supplied [C client][client-c] returns allocated JSON text. Copy `content`
into the tool message, then free it.

[client-c]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/starter_templates/c/code/src/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

```cpp
if (!opened_uris.contains(uri)) {
    lsp.call("notify", open_payload);
    opened_uris.insert(uri);
}
std::string content = lsp.call("request", definition_payload).dump();
```

{{/lang_is_cpp}}

{{#lang_is_csharp}}

```csharp
if (!openedUris.Contains(uri)) {
    await lsp.Call("notify", JsonSerializer.Serialize(openPayload));
    openedUris.Add(uri);
}
string content = await lsp.Call("request", JsonSerializer.Serialize(definitionPayload));
```

Use `System.Text.Json` in addition to the collection import above. Successful
`lsp.Call` results are JSON text.

{{/lang_is_csharp}}

{{#lang_is_zig}}

```zig
if (!opened_uris.contains(uri)) {
    const ack = try lsp.call("notify", open_json);
    allocator.free(ack);
    const saved_uri = try allocator.dupe(u8, uri);
    errdefer allocator.free(saved_uri);
    try opened_uris.put(saved_uri, {});
}
const content = try lsp.call("request", definition_json);
defer allocator.free(content);
```

Use the supplied [Zig client][client-zig] with the optional-client cleanup from
Stage 1. Copy `content` into the tool message before freeing it.

[client-zig]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/starter_templates/zig/code/src/lsp_client.zig

{{/lang_is_zig}}

### 4. Return the location to the model

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

The returned URI points to `pricing.py`. The zero-based range covers the name
`total` in its definition, starting at the `t` and ending just after the name.

Put the code's `content` string in a tool message's `content` field. Set
`tool_call_id` to the ID of the model's LSP call and continue the agent loop.
Serialize the server result once; clients returning JSON text need no additional
serialization.

Keep the returned URI and range unchanged. The model decodes the file URI to
obtain a path for Read. Your LSP handler returns the location; the model chooses
the subsequent Read call.

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

Your agent can now follow a call to its definition and let the model inspect
the implementation. Next, you'll find where that function is used.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
