In this stage, you'll implement `goToDefinition` so your agent can find the function behind a call.

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

Replace Stage 2's temporary LSP handler with definition handling. Reuse Stage 1's
client and `extensionToLanguage` mapping and Stage 2's tool specification. Your
handler must accept this `LSP` tool call from the model:

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

### 1. Send the source document

Your Read tool returns file contents to the model. To query `checkout.py`, send
its full contents to the language server in a `textDocument/didOpen` notification.

Load `filePath` using your Read handler's path resolution and UTF-8 reading.
Resolve relative paths against the agent's working directory, which the tester
sets to the invoice project. Convert the absolute path to a file URI, encoding
special characters:
`/project/cart notes.py` becomes `file:///project/cart%20notes.py`.

Pass this complete [`didOpen` object][did-open] to the client's `notify` action.
Replace `uri` with the resolved file URI and `text` with the complete file contents.
Set `languageId` from `extensionToLanguage` (`.py` maps to `python`):

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

Version 1 identifies the file's initial contents. Stage 5 adds edit synchronization.

### 2. Request the definition

The `notify` action sends document contents; `request` asks for a definition
location. Pass the complete [`definition` object][definition] below to `request`.
Use the same `checkout.py` URI as `didOpen`. Subtract one from the tool's `line`
and `character`: line 5, character 12 becomes zero-based LSP
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

### 3. Track open documents and return the result

Keep a record of opened files keyed by URI for the current server connection.
Send `didOpen` before a file's first query and mark its URI open only after the
client's `notify` call succeeds. Later queries for that URI skip `didOpen`.

In the code below, `isOpen`/`is_open` is the flag for the queried file's URI.
Start with a false flag for a URI you haven't opened. Save the updated flag in
that URI's record after the client calls.

{{#lang_is_python}}

```python
if not is_open:
    lsp.call("notify", open_payload)
    is_open = True
result = lsp.call("request", definition_payload)
content = json.dumps(result)
```

Use the standard `json` module.

{{/lang_is_python}}

{{#lang_is_javascript}}

```javascript
if (!isOpen) {
  await lsp.call("notify", openPayload);
  isOpen = true;
}
const result = await lsp.call("request", definitionPayload);
const content = JSON.stringify(result);
```

{{/lang_is_javascript}}

{{#lang_is_typescript}}

```typescript
if (!isOpen) {
  await lsp.call("notify", openPayload);
  isOpen = true;
}
const result = await lsp.call("request", definitionPayload);
const content = JSON.stringify(result)!;
```

{{/lang_is_typescript}}

{{#lang_is_go}}

```go
if !isOpen {
    if _, err := lsp.Call("notify", openPayload); err != nil {
        log.Fatal(err)
    }
    isOpen = true
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
if (!isOpen) {
    lsp.call("notify", mapper.writeValueAsString(openPayload));
    isOpen = true;
}
String content = lsp.call("request", mapper.writeValueAsString(definitionPayload));
```

Jackson is included by the starter. Successful `lsp.call` results are JSON text.

{{/lang_is_java}}

{{#lang_is_rust}}

```rust
if !is_open {
    lsp.call("notify", &open_payload)?;
    is_open = true;
}
let result = lsp.call("request", &definition_payload)?;
let content = result.to_string();
```

Use `?` in a function returning a compatible `Result`, as in Stage 1.

{{/lang_is_rust}}

{{#lang_is_c}}

Serialize the `didOpen` object as `open_json` and the definition request object
as `definition_json`.

```c
if (!is_open) {
    char *ack = lsp_call("notify", open_json);
    if (!ack) exit(1);
    free(ack);
    is_open = 1;
}
char *content = lsp_call("request", definition_json);
if (!content) exit(1);
```

The supplied [C client][client-c] returns allocated JSON text. Copy `content`
into the tool message, then free it.

[client-c]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/c/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

```cpp
if (!is_open) {
    lsp.call("notify", open_payload);
    is_open = true;
}
std::string content = lsp.call("request", definition_payload).dump();
```

{{/lang_is_cpp}}

{{#lang_is_csharp}}

```csharp
if (!isOpen) {
    await lsp.Call("notify", JsonSerializer.Serialize(openPayload));
    isOpen = true;
}
string content = await lsp.Call("request", JsonSerializer.Serialize(definitionPayload));
```

Use `System.Text.Json`. Successful `lsp.Call` results are JSON text.

{{/lang_is_csharp}}

{{#lang_is_zig}}

Serialize the `didOpen` object as `open_json` and the definition request object
as `definition_json`.

```zig
if (!is_open) {
    const ack = try lsp.call("notify", open_json);
    allocator.free(ack);
    is_open = true;
}
const content = try lsp.call("request", definition_json);
defer allocator.free(content);
```

Use the supplied [Zig client][client-zig] with `var lsp` and `defer lsp.deinit()`.
Copy `content` into the tool message before freeing it.

[client-zig]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/zig/lsp_client.zig

{{/lang_is_zig}}

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

The LSP tool result must contain pricing's definition location shown above, with
the tester's actual project URI. The following Read result must contain:

```json
"def total(price: int, quantity: int) -> int:\n    return price * quantity\n"
```

This stage tests one successful lookup followed by Read, using valid Python
files and a single definition location. Multiple definitions, missing definitions,
and server-error tool results aren't required here. The final explanation can vary.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
