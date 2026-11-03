In this stage, you'll connect the supplied LSP client and advertise the `LSP` tool.

### How the connection works

The **[Language Server Protocol (LSP)][lsp]** lets programs ask a language server
about code, such as where a function is defined.

- **Agent:** executes the model's tool calls.
- **Client:** supplied file that forwards calls to the helper.
- **Helper:** starts the server and handles LSP messages.
- **Language server:** analyzes project code and answers definition/reference requests.

```text
Agent -> supplied client -> helper -> language server
```

In later stages, `invoice_total` in the supplied [invoice project][example]'s
`checkout.py` resolves to `pricing.py`. Your agent sends a definition request
through the client, then returns the server's location to the model. The tester
supplies this Python project for every agent language. No server installation is needed.

### Your task

Before your first model request:

1. Copy the **entire client file** below to its shown path if missing.
2. Call `configuration` with `{}` before the agent loop. Save
   `extensionToLanguage` for your tool handler.
3. Add the LSP specification below to your model requests' `tools` array
   alongside Read, Write, and Bash.

Return a "not implemented yet" tool result for LSP calls, with the matching
`tool_call_id`.

### Connect the client

Use the supplied file with this setup:

{{#lang_is_c}}

If missing, copy the **entire [client file][client-c]** to `src/lsp_client.h`. At the top of your agent's C source, add:

```c
#include "lsp_client.h"
#include <cjson/cJSON.h>
```

Inside `main`, after your existing `curl_global_init` and before the agent loop:

```c
char *configuration_json = lsp_call("configuration", "{}");
if (!configuration_json) return 1;
cJSON *configuration = cJSON_Parse(configuration_json);
free(configuration_json);
if (!configuration) return 1;
cJSON *extension_to_language = cJSON_GetObjectItemCaseSensitive(
    configuration, "extensionToLanguage");
```

There is no client constructor: each `lsp_call` uses the supplied connection.
Keep `configuration` alive while using `extension_to_language`. Call
`cJSON_Delete(configuration)` after the agent loop. Keep your existing libcurl
cleanup after the loop too.

[client-c]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/c/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

If missing, copy the **entire [client file][client-cpp]** to `src/lsp_client.hpp`. At the top of your C++ source, add:

```cpp
#include "lsp_client.hpp"
```

Before the agent loop:

```cpp
LSPClient lsp;
auto configuration = lsp.call("configuration", nlohmann::json::object());
auto extension_to_language = configuration.at("extensionToLanguage");
```

The client uses the starter's existing CPR and nlohmann JSON dependencies.
Constructor, HTTP, and JSON errors propagate as exceptions. Handle them with
your agent's existing exception handling.

[client-cpp]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/cpp/lsp_client.hpp

{{/lang_is_cpp}}

{{#lang_is_csharp}}

If missing, copy the **entire [client file][client-csharp]** to `src/LSPClient.cs`. The starter includes `.cs` files under `src/`
automatically. No client import is needed. Add this using directive:

```csharp
using System.Text.Json;
```

In your top-level startup code or an async startup method:

```csharp
var lsp = new LSPClient();
string configurationJson = await lsp.Call("configuration", "{}");
using var configuration = JsonDocument.Parse(configurationJson);
var extensionToLanguage = configuration.RootElement.GetProperty("extensionToLanguage");
```

`Call` returns a `Task<string>` and must be awaited. Keep `configuration` alive
while using `extensionToLanguage`. Handle exceptions with your agent's existing
error handling.

[client-csharp]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/csharp/LSPClient.cs

{{/lang_is_csharp}}

{{#lang_is_go}}

If missing, copy the **entire [client file][client-go]** to `app/lsp_client.go`. Keep it in the same `package main` as your agent. No
client import is needed. Add `encoding/json` and `log` to your imports, then
place this inside your startup function:

```go
lsp, err := NewLSPClient()
if err != nil {
    log.Fatal(err)
}
configurationJSON, err := lsp.Call("configuration", map[string]any{})
if err != nil {
    log.Fatal(err)
}
var configuration struct {
    ExtensionToLanguage map[string]string `json:"extensionToLanguage"`
}
if err := json.Unmarshal(configurationJSON, &configuration); err != nil {
    log.Fatal(err)
}
```

Use `configuration.ExtensionToLanguage` in your tool handler. Run the whole
package with `go run ./app`, rather than compiling only `app/main.go`.

[client-go]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/go/lsp_client.go

{{/lang_is_go}}

{{#lang_is_java}}

If missing, copy the **entire [client file][client-java]** to `src/main/java/LSPClient.java`. It shares the starter's default package with
`Main`, so no client import is needed. Inside your startup method:

```java
var lsp = new LSPClient();
String configurationJson = lsp.call("configuration", "{}");
```

The response is a JSON string. Parse it with your agent's JSON library and save
its `extensionToLanguage` object. `call` throws checked exceptions: catch them
with your existing error handling, or declare `throws Exception` on your
startup method, including `main` if you put this code there.

[client-java]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/java/LSPClient.java

{{/lang_is_java}}

{{#lang_is_javascript}}

If missing, copy the **entire [client file][client-javascript]** to `app/lsp_client.js`. From another file in `app/`, import the client and await
the configuration call at module scope or inside your async startup function:

```javascript
import { LSPClient } from "./lsp_client.js";

const lsp = new LSPClient();
const configuration = await lsp.call("configuration", {});
const extensionToLanguage = configuration.extensionToLanguage;
```

[client-javascript]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/javascript/lsp_client.js

{{/lang_is_javascript}}

{{#lang_is_python}}

If missing, copy the **entire [client file][client-python]** to `app/lsp_client.py`. In your agent's Python module:

```python
from app.lsp_client import LSPClient

lsp = LSPClient()
configuration = lsp.call("configuration", {})
extension_to_language = configuration["extensionToLanguage"]
```

[client-python]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/python/lsp_client.py

{{/lang_is_python}}

{{#lang_is_rust}}

If missing, copy the **entire [client file][client-rust]** to `src/lsp_client.rs`. At the top level of `src/main.rs`, add:

```rust
mod lsp_client;
use lsp_client::LspClient;
```

Inside your existing `main` or startup function:

```rust
let lsp = LspClient::new()?;
let configuration = lsp.call("configuration", &serde_json::json!({}))?;
let extension_to_language = configuration["extensionToLanguage"]
    .as_object()
    .ok_or("Missing extensionToLanguage mapping")?;
```

The type is `LspClient`. Both `new` and `call` return a `Result`. The `?`
operator propagates errors from a function returning a compatible `Result`,
such as the starter's `Result<(), Box<dyn std::error::Error>>`. If your startup
function returns another type, handle these results explicitly instead.

[client-rust]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/rust/lsp_client.rs

{{/lang_is_rust}}

{{#lang_is_typescript}}

If missing, copy the **entire [client file][client-typescript]** to `app/lsp_client.ts`. From another file in `app/`, import the client and await
the configuration call at module scope or inside your async startup function.
The client returns `unknown`. Give this action's response its expected type:

```typescript
import { LSPClient } from "./lsp_client.ts";

const lsp = new LSPClient();
const configuration = await lsp.call("configuration", {}) as {
  extensionToLanguage: Record<string, string>;
};
const extensionToLanguage = configuration.extensionToLanguage;
```

[client-typescript]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/typescript/lsp_client.ts

{{/lang_is_typescript}}

{{#lang_is_zig}}

If missing, copy the **entire [client file][client-zig]** to `src/lsp_client.zig`. At the top of `src/main.zig`, add:

```zig
const LSPClient = @import("lsp_client.zig").LSPClient;
```

Inside `main(init: std.process.Init) !void`, after the starter's `allocator` and
`io` declarations:

```zig
var lsp = try LSPClient.init(
    allocator, io, init.environ_map.get("CODECRAFTERS_LSP_URL"));
defer lsp.deinit();
const configuration_json = try lsp.call("configuration", "{}");
defer allocator.free(configuration_json);
const configuration = try std.json.parseFromSlice(
    std.json.Value, allocator, configuration_json, .{});
defer configuration.deinit();
const extension_to_language = configuration.value.object
    .get("extensionToLanguage").?.object;
```

`init` and `call` return error unions, so use `try` from a function returning an
error union, as the starter does. Keep the response and parsed configuration
alive until after the agent loop. The deferred cleanup above runs on exit.

[client-zig]: https://github.com/codecrafters-io/claude-code-lsp-snippets/blob/main/zig/lsp_client.zig

{{/lang_is_zig}}

The helper's `configuration` action returns:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

Store `{ ".py": "python" }`. Look up `.py` to get language ID `python`.

### Advertise the LSP tool

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Returns raw language-server results with file URIs and zero-based UTF-16 ranges.",
    "parameters": {
      "type": "object",
      "properties": {
        "operation": {
          "type": "string",
          "enum": ["goToDefinition"]
        },
        "filePath": {
          "type": "string",
          "description": "Absolute path, or a path relative to the agent's current working directory."
        },
        "line": {
          "type": "integer",
          "minimum": 1,
          "description": "1-based line number of the symbol."
        },
        "character": {
          "type": "integer",
          "minimum": 1,
          "description": "1-based character offset in UTF-16 code units (same as character count for ASCII)."
        }
      },
      "required": ["operation", "filePath", "line", "character"]
    }
  }
}
```

Add this guidance to your existing system prompt:

```text
Use LSP for code navigation. Tool positions are one-based UTF-16.
Edit files with Write so the language server sees changes.
```

### Tests

The tester supplies the invoice project and runs:

```bash
$ ./your_program.sh -p "Use only Read to inspect checkout.py and pricing.py. Explain how checkout uses the pricing function."
```

The configuration result must be:

```json
{ "extensionToLanguage": { ".py": "python" } }
```

The two Read tool results must preserve these exact file contents:

```json
"from pricing import total as invoice_total\n\n\ndef checkout_total() -> int:\n    return invoice_total(250, 2)\n"
```

```json
"def total(price: int, quantity: int) -> int:\n    return price * quantity\n"
```

The model's final explanation can vary. This stage requests only Read.

Optional: [run locally][local-run].

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[local-run]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/advanced_usage.md#run-with-your-own-server
[lsp]: https://microsoft.github.io/language-server-protocol/
