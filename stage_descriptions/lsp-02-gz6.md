In this stage, you'll implement `goToDefinition` so your agent can find the function behind a call.

### Why look up a definition?

To explain checkout's calculation, the model reads `checkout.py`:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

`goToDefinition` resolves `invoice_total` to `pricing.total`. Read retrieves
its implementation.

### Implement your LSP handler

Replace setup's "not implemented yet" branch with definition handling. Reuse
its client and extension mapping. Handle this model tool call:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

### 1. Give the server the source file

Reuse Read's path resolution and UTF-8 reading. Resolve relative paths against
the agent's working directory, which the tester sets to the invoice project.
Resolve symlinks, then convert the absolute path to a file URI, encoding special characters:
`/project/cart notes.py` becomes `file:///project/cart%20notes.py`.

Send action `notify` with this [`didOpen` payload][did-open] once per URI.
Substitute the actual URI, complete text, and mapped `languageId`:

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

Track successfully opened URIs. Wait for notification completion before requesting.

### 2. Ask where the function is defined

Send action `request` with this [`definition` payload][definition]. Reuse the
URI. Subtract one from the input line and character. LSP [positions][position]
use zero-based UTF-16 columns.

```json
{
  "method": "textDocument/definition",
  "params": {
    "textDocument": { "uri": "file:///project/checkout.py" },
    "position": { "line": 4, "character": 11 }
  }
}
```

### 3. Call your client and return the result

Use the complete payloads above. `isOpen`/`is_open` is the current URI's stored
flag. Save its updated value even if the request fails.

{{#lang_is_python}}

```python
try:
    if not is_open:
        lsp.call("notify", open_payload)
        is_open = True
    result = lsp.call("request", definition_payload)
    content = json.dumps(result)
except Exception as error:
    content = json.dumps({"error": str(error)})
```

Use the standard `json` module.

{{/lang_is_python}}

{{#lang_is_javascript}}

```javascript
let content;
try {
  if (!isOpen) {
    await lsp.call("notify", openPayload);
    isOpen = true;
  }
  const result = await lsp.call("request", definitionPayload);
  content = JSON.stringify(result);
} catch (error) {
  content = JSON.stringify({ error: String(error) });
}
```

{{/lang_is_javascript}}

{{#lang_is_typescript}}

```typescript
let content: string;
try {
  if (!isOpen) {
    await lsp.call("notify", openPayload);
    isOpen = true;
  }
  const result = await lsp.call("request", definitionPayload);
  content = JSON.stringify(result)!;
} catch (error) {
  content = JSON.stringify({
    error: error instanceof Error ? error.message : String(error),
  });
}
```

{{/lang_is_typescript}}

{{#lang_is_go}}

```go
var result json.RawMessage
var callErr error
if !isOpen {
    _, callErr = lsp.Call("notify", openPayload)
    if callErr == nil {
        isOpen = true
    }
}
if callErr == nil {
    result, callErr = lsp.Call("request", definitionPayload)
}
content := string(result)
if callErr != nil {
    failure, _ := json.Marshal(map[string]string{"error": callErr.Error()})
    content = string(failure)
}
```

Import `encoding/json`. The successful result is already serialized JSON.

{{/lang_is_go}}

{{#lang_is_java}}

```java
var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
String content;
try {
    if (!isOpen) {
        lsp.call("notify", mapper.writeValueAsString(openPayload));
        isOpen = true;
    }
    content = lsp.call("request", mapper.writeValueAsString(definitionPayload));
} catch (Exception error) {
    content = mapper.writeValueAsString(java.util.Map.of("error", error.toString()));
}
```

Jackson is included by the starter. Successful responses are already JSON text.

{{/lang_is_java}}

{{#lang_is_rust}}

```rust
let response = (|| -> Result<serde_json::Value, Box<dyn std::error::Error>> {
    if !is_open {
        lsp.call("notify", &open_payload)?;
        is_open = true;
    }
    lsp.call("request", &definition_payload)
})();
let content = match response {
    Ok(result) => result.to_string(),
    Err(error) => serde_json::json!({"error": error.to_string()}).to_string(),
};
```

The closure captures errors for the tool result, keeping the agent loop running.

{{/lang_is_rust}}

{{#lang_is_c}}

Serialize the payloads as `open_json` and `definition_json` first.

```c
char *result = NULL;
if (!is_open) {
    char *ack = lsp_call("notify", open_json);
    if (ack) {
        free(ack);
        is_open = 1;
    }
}
if (is_open) result = lsp_call("request", definition_json);
char *content;
if (result) {
    content = result;
} else {
    cJSON *failure = cJSON_CreateObject();
    cJSON_AddStringToObject(failure, "error", lsp_last_error());
    content = cJSON_PrintUnformatted(failure);
    cJSON_Delete(failure);
}
```

Use the updated [client][client-c] for `lsp_last_error()`. Copy `content` into
the tool message, then free it.

[client-c]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/c/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

```cpp
std::string content;
try {
    if (!is_open) {
        lsp.call("notify", open_payload);
        is_open = true;
    }
    content = lsp.call("request", definition_payload).dump();
} catch (const std::exception& error) {
    auto failure = nlohmann::json::object();
    failure["error"] = error.what();
    content = failure.dump();
}
```

{{/lang_is_cpp}}

{{#lang_is_csharp}}

```csharp
string content;
try {
    if (!isOpen) {
        await lsp.Call("notify", JsonSerializer.Serialize(openPayload));
        isOpen = true;
    }
    content = await lsp.Call("request", JsonSerializer.Serialize(definitionPayload));
} catch (Exception error) {
    content = JsonSerializer.Serialize(new { error = error.Message });
}
```

Use `System.Text.Json`. Successful responses are already JSON text.

{{/lang_is_csharp}}

{{#lang_is_zig}}

Serialize the payloads as `open_json` and `definition_json` first.

```zig
const content = response: {
    if (!is_open) {
        const ack = lsp.call("notify", open_json) catch |err| {
            break :response try std.json.Stringify.valueAlloc(allocator,
                .{ .@"error" = lsp.lastError() orelse @errorName(err) }, .{});
        };
        allocator.free(ack);
        is_open = true;
    }
    break :response lsp.call("request", definition_json) catch |err|
        try std.json.Stringify.valueAlloc(allocator,
            .{ .@"error" = lsp.lastError() orelse @errorName(err) }, .{});
};
defer allocator.free(content);
```

Use the updated [client][client-zig] with `var lsp` and `defer lsp.deinit()`.
Copy `content` into the tool message before freeing it.

[client-zig]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/zig/lsp_client.zig

{{/lang_is_zig}}

A definition result can be:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

Use the computed `content` and matching `tool_call_id`. Preserve locations,
arrays, and null. Keep returned URIs and ranges unchanged. The model decodes
URIs for Read and converts positions back to one-based for later LSP calls.

Use the same error-result pattern for unknown operations, missing files, and
unmapped extensions. Preserve the helper's error message and continue the loop.

### Tests

The tester writes the invoice project and runs:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. Read the returned implementation and explain which total is called; preview.total is unrelated."
```

With `/project` representing the actual project directory, the matching LSP tool
result must preserve:

```json
{"uri":"file:///project/pricing.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
```

The subsequent Read result must preserve:

```json
"def total(price: int, quantity: int) -> int:\n    return price * quantity\n"
```

Other cases return an array, null, and error `-32603` (`"Definition unavailable"`).
Preserve the server's error message. The final explanation can vary.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
