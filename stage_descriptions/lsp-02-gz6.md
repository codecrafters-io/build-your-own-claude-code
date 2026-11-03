In this stage, you'll implement `goToDefinition` so your agent can find the function behind a call.
You'll replace Stage 1's temporary LSP response with a working lookup, then let
the model use Read to inspect the implementation it finds.

### Why look up a definition?

In Stage 1, the model read `checkout.py` and `pricing.py` directly. This time,
you'll give it a way to discover which implementation to read. The starting point
is the call in `checkout.py`:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

The name `invoice_total` is an alias for `pricing.total`. Searching for the alias
finds the import and call, so the model can follow that import manually. Searching
for `total` can also find unrelated functions, such as `preview.total`.

Definition lookup asks a more precise question: "Which definition does the symbol
at this position refer to?" The language server follows the alias and returns a
location in `pricing.py`. **LSP finds the implementation; Read retrieves its
contents.** Your handler returns the location to the model, which can then choose
to call Read. The LSP handler itself doesn't need to execute Read.

### Implement your LSP handler

Replace the "not implemented yet" branch with definition handling. Reuse the
client, extension mapping, and tool specification from Stage 1. Handle this model
tool call:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

Line 5, character 12 points to the first character of `invoice_total` in the
return statement. A position tells the server which occurrence to resolve, even
when several symbols share a name.

Your handler will give the server the source text, ask for the definition at that
position, and return the answer as a tool result. The helper handles message
delivery; your agent supplies the document and the question.

### 1. Give the server the source file

Reading a file with Read gives its contents to the model. It doesn't send those
contents to the language server. Use a `textDocument/didOpen` notification to give
the server the document your query will refer to. Here, "open" means your agent
has sent the document to the server; it doesn't mean opening an editor window.

Reuse Read's path resolution and UTF-8 reading to load the source file. Resolve
relative paths against the agent's working directory, which the tester sets to
the invoice project. Resolve symlinks so two paths to the same file use the same
document identity.

LSP identifies files with URIs. Convert the resolved absolute path to a file URI,
encoding special characters: `/project/cart notes.py` becomes
`file:///project/cart%20notes.py`. Use your language's file-URI conversion rather
than just adding `file://` to the path.

Send the helper action `notify` with this complete [`didOpen` payload][did-open].
The helper action says how to deliver the message; `method` identifies the LSP
notification to send. Substitute the actual URI and complete file contents, and
look up the file's extension in the mapping saved in Stage 1 to get `languageId`:

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

`version: 1` identifies the initial contents you send. You'll use later versions
when you add edit synchronization in Stage 4.

Keep a record of successfully opened URIs for the lifetime of this connection.
Send `didOpen` once per URI, before its first query. Later queries reuse that open
document. Wait for the client call to complete before sending the definition
request, and mark the URI open only if the notification call succeeds.

### 2. Ask where the function is defined

Now send the helper action `request` with this complete
[`definition` payload][definition]. Unlike a notification, a request asks the
server to return an answer. Your model-facing operation `goToDefinition` becomes
the LSP method `textDocument/definition`.

Reuse the URI from `didOpen`. The tool's line and character inputs start at 1,
while LSP [positions][position] start at 0. Subtract one from each: input line 5,
character 12 becomes line 4, character 11. Both interfaces count columns in UTF-16
code units, which match character counts for the ASCII text in this example.

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

Use the two complete payloads above with your language's client-call pattern
below. `isOpen`/`is_open` is the flag stored for the current URI, not a single flag
shared by all files.

Save its updated value even if the definition request fails. If `didOpen`
succeeded, the document is already open; a failed lookup doesn't undo that.

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

For the example call, a definition result can be:

```json
{
  "uri": "file:///project/pricing.py",
  "range": {
    "start": { "line": 0, "character": 4 },
    "end": { "line": 0, "character": 9 }
  }
}
```

The URI identifies `pricing.py`. The zero-based range starts at line 0, character
4: the `t` in `def total`. Its end position, character 9, is just after `total`.
This is the symbol's location, not the function's source text.

Put the computed `content` in a tool message with the matching `tool_call_id`,
then continue the agent loop so the model receives the answer. The content must
be a string containing the JSON result. If your client already returns JSON text,
use it directly; serializing that text again would turn the result into a JSON
string instead of a location object.

Preserve the server's response shape: a single location stays an object, an array
stays an array, and `null` stays `null`. A null result means no definition was
found; it isn't a transport error. Keep returned URIs and ranges unchanged. The
model decodes the file URI to obtain a path for Read. If it uses a returned
position in another LSP tool call, it converts that position back to one-based.

Use the same error-result pattern for unknown operations, missing files, and
unmapped extensions. Return an error instead of inventing a language ID for an
unsupported extension. Preserve the helper's error message when a call fails and
continue the loop, so the model can see what went wrong and decide what to do next.

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

Together, these results show the complete navigation flow: the model asks about
the alias in checkout, receives pricing's definition location, and reads that
implementation. `preview.total` is unrelated and should not be chosen just
because it has the same function name.

Other cases return an array, null, and error `-32603` (`"Definition unavailable"`).
These exercise the response and error handling above. Preserve the server's error
message. The final explanation can vary.

[position]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position
[did-open]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_didOpen
[definition]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
