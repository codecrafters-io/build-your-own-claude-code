In this stage, you'll make the `LSP` tool available to the model.

### Why LSP?

Searching for a function name can find unrelated functions or miss uses through
an alias. A language server analyzes a project's code to connect those uses to
their definitions. The Language Server Protocol (LSP) lets your agent ask that
server where a symbol is defined, just as an editor does.

### Expected behavior

The supplied client connects to the language server started by the tester.
Your agent must initialize the client before its first model request and keep
the connection available throughout the run. When connected, every model request
must advertise the `LSP` tool below. When unconfigured, the agent continues with
its existing tools.

For now, an LSP call receives a placeholder such as `LSP is not implemented yet`
as a tool result with the matching `tool_call_id`. The agent then continues its
conversation with the model. Definition lookup comes in the next stage.

```json
{
  "type": "function",
  "function": {
    "name": "LSP",
    "description": "Returns the file, line, and character where a symbol is defined.",
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

The arguments point at a spot in a file rather than a name, because `total`
alone could mean the one in `pricing.py`, `discounts.py`, or `preview.py`. For
example, to point at `invoice_total` in `checkout.py`'s return statement, the
model sends line 5, character 12. Both count from 1, as in an editor:

```json
{
  "operation": "goToDefinition",
  "filePath": "checkout.py",
  "line": 5,
  "character": 12
}
```

The model should understand that the tool finds definitions and that its inputs
are one-based. The tool description or your system prompt can provide this
information.

### Supplied client

The client handles the server connection and fetches its configuration during
initialization. Use the factory for your language:

{{#lang_is_c}}

The supplied client is [lsp_client.h][client-c], at `src/lsp_client.h`.
Its initialization call is `lsp_from_environment(&lsp)`. `1` means connected, `0` unconfigured, and `-1` an initialization error.

{{/lang_is_c}}

{{#lang_is_cpp}}

The supplied client is [lsp_client.hpp][client-cpp], at `src/lsp_client.hpp`.
Its initialization call is `LSPClient::from_environment()`. It returns an optional client, with `std::nullopt` when unconfigured.

{{/lang_is_cpp}}

{{#lang_is_csharp}}

The supplied client is [LSPClient.cs][client-csharp], at `src/LSPClient.cs`.
Its initialization call is `await LSPClient.FromEnvironmentAsync()`. It returns a client, or `null` when unconfigured.

{{/lang_is_csharp}}

{{#lang_is_go}}

The supplied client is [lsp_client.go][client-go], at `app/lsp_client.go`.
Its initialization call is `LSPClientFromEnvironment()`. It returns a client and an error; the client is `nil` when unconfigured.

{{/lang_is_go}}

{{#lang_is_java}}

The supplied client is [LSPClient.java][client-java], at `src/main/java/LSPClient.java`.
Its initialization call is `LSPClient.fromEnvironment()`. It returns a client, or `null` when unconfigured. Initialization can throw checked exceptions.

{{/lang_is_java}}

{{#lang_is_javascript}}

The supplied client is [lsp_client.js][client-javascript], at `app/lsp_client.js`.
Its initialization call is `await LSPClient.fromEnvironment()`. It returns a client, or `null` when unconfigured.

{{/lang_is_javascript}}

{{#lang_is_python}}

The supplied client is [lsp_client.py][client-python], at `app/lsp_client.py`.
Its initialization call is `LSPClient.from_environment()`. It returns a client, or `None` when unconfigured.

{{/lang_is_python}}

{{#lang_is_rust}}

The supplied client is [lsp_client.rs][client-rust], at `src/lsp_client.rs`.
Its initialization call is `LspClient::from_environment()`. It returns a `Result` holding an optional client, with `None` when unconfigured.

{{/lang_is_rust}}

{{#lang_is_typescript}}

The supplied client is [lsp_client.ts][client-typescript], at `app/lsp_client.ts`.
Its initialization call is `await LSPClient.fromEnvironment()`. It returns a client, or `null` when unconfigured.

{{/lang_is_typescript}}

{{#lang_is_zig}}

The supplied client is [lsp_client.zig][client-zig], at `src/lsp_client.zig`.
Its initialization call is `LSPClient.fromEnvironment(allocator, io, init.environ_map)`. It returns an error union holding an optional client, with `null` when unconfigured.

{{/lang_is_zig}}

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. If navigation is not implemented yet, report the tool response without retrying."
LSP client connected
<the model's report of the tool response>
```

The tester will verify that:

- Your program connects the supplied LSP client before its first model request
- Every model request advertises the `LSP` tool, with `operation`, `filePath`, `line`, and `character` required
- The model's `goToDefinition` call gets a tool result, with the matching `tool_call_id`
- Your program exits with code `0`

### Hint: connecting the client

These examples show imports and initialization for the supplied starter. Adapt
the placement to your agent's startup code.

{{#lang_is_c}}

Download [`lsp_client.h`][client-c] and save it as `src/lsp_client.h`.

At the top of `src/main.c`, add:

```c
#include "lsp_client.h"
```

Inside `main`, after your existing `curl_global_init` and before the agent loop:

```c
LSPClient lsp;
int lsp_status = lsp_from_environment(&lsp); // 1: connected, 0: not configured, -1: error
if (lsp_status < 0) return 1;
if (lsp_status == 1) {
    fprintf(stderr, "LSP client connected\n");
}
```

Call `lsp_deinit(&lsp)` after the agent loop, before your existing libcurl
cleanup.

[client-c]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/c/code/src/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

Download [`lsp_client.hpp`][client-cpp] and save it as `src/lsp_client.hpp`.

At the top of `src/main.cpp`, add:

```cpp
#include "lsp_client.hpp"
```

Inside `main`, before the agent loop:

```cpp
auto lsp = LSPClient::from_environment(); // std::nullopt when not configured
if (lsp) {
    std::cerr << "LSP client connected\n";
}
```

The client uses the CPR and nlohmann JSON libraries your starter already
includes.

[client-cpp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/cpp/code/src/lsp_client.hpp

{{/lang_is_cpp}}

{{#lang_is_csharp}}

Download [`LSPClient.cs`][client-csharp] and save it as `src/LSPClient.cs`.

No import is needed, because the starter compiles every `.cs` file under
`src/`. In `src/Program.cs`, after the prompt is read:

```csharp
var lsp = await LSPClient.FromEnvironmentAsync(); // null when not configured
if (lsp is not null) {
    Console.Error.WriteLine("LSP client connected");
}
```

[client-csharp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/csharp/code/src/LSPClient.cs

{{/lang_is_csharp}}

{{#lang_is_go}}

Download [`lsp_client.go`][client-go] and save it as `app/lsp_client.go`.

The client shares the same `package main` as your agent, so no client import is
needed. Add `log` to your imports, then place this at the start of `main` in
`app/main.go`:

```go
lsp, err := LSPClientFromEnvironment() // lsp is nil when not configured
if err != nil {
    log.Fatal(err)
}
if lsp != nil {
    log.Print("LSP client connected")
}
```

[client-go]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/go/code/app/lsp_client.go

{{/lang_is_go}}

{{#lang_is_java}}

Download [`LSPClient.java`][client-java] and save it as `src/main/java/LSPClient.java`.

It shares the starter's default package with `Main`, so no client import is
needed. At the start of `main` in `src/main/java/Main.java`:

```java
var lsp = LSPClient.fromEnvironment(); // null when not configured
if (lsp != null) {
    System.err.println("LSP client connected");
}
```

`fromEnvironment` throws checked exceptions, so add `throws Exception` to
`main`.

[client-java]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/java/code/src/main/java/LSPClient.java

{{/lang_is_java}}

{{#lang_is_javascript}}

Download [`lsp_client.js`][client-javascript] and save it as `app/lsp_client.js`.

At the top of `app/main.js`, add:

```javascript
import { LSPClient } from "./lsp_client.js";
```

At the start of your `main` function:

```javascript
const lsp = await LSPClient.fromEnvironment(); // null when not configured
if (lsp !== null) {
    console.error("LSP client connected");
}
```

[client-javascript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/javascript/code/app/lsp_client.js

{{/lang_is_javascript}}

{{#lang_is_python}}

Download [`lsp_client.py`][client-python] and save it as `app/lsp_client.py`.

At the top of `app/main.py`, add:

```python
from app.lsp_client import LSPClient
```

At the start of `main()`:

```python
lsp = LSPClient.from_environment()  # None when not configured
if lsp is not None:
    print("LSP client connected", file=sys.stderr)
```

[client-python]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/python/code/app/lsp_client.py

{{/lang_is_python}}

{{#lang_is_rust}}

Download [`lsp_client.rs`][client-rust] and save it as `src/lsp_client.rs`.

At the top level of `src/main.rs`, add:

```rust
mod lsp_client;
use lsp_client::LspClient;
```

At the start of `main`:

```rust
let lsp = LspClient::from_environment()?; // None when not configured
if lsp.is_some() {
    eprintln!("LSP client connected");
}
```

[client-rust]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/rust/code/src/lsp_client.rs

{{/lang_is_rust}}

{{#lang_is_typescript}}

Download [`lsp_client.ts`][client-typescript] and save it as `app/lsp_client.ts`.

At the top of `app/main.ts`, add:

```typescript
import { LSPClient } from "./lsp_client.ts";
```

At the start of your `main` function:

```typescript
const lsp = await LSPClient.fromEnvironment(); // null when not configured
if (lsp !== null) {
    console.error("LSP client connected");
}
```

[client-typescript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/typescript/code/app/lsp_client.ts

{{/lang_is_typescript}}

{{#lang_is_zig}}

Download [`lsp_client.zig`][client-zig] and save it as `src/lsp_client.zig`.

At the top of `src/main.zig`, add:

```zig
const LSPClient = @import("lsp_client.zig").LSPClient;
```

Inside `main(init: std.process.Init) !void`, after the starter's `allocator` and
`io` declarations:

```zig
var lsp = try LSPClient.fromEnvironment(allocator, io, init.environ_map); // null when not configured
defer if (lsp) |*client| client.deinit();
if (lsp != null) {
    std.debug.print("LSP client connected\n", .{});
}
```

[client-zig]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/zig/code/src/lsp_client.zig

{{/lang_is_zig}}

### Hint: guiding the model

Your system prompt can include:

```text
Use the LSP tool to find where a symbol is defined. Lines and characters are 1-based, as in an editor.
```

### Notes

- `LSP client connected` is a startup log on standard error. Standard output is reserved for the model's answer.
- Only `goToDefinition` is offered for now. Reference lookup and a handler that contacts the language server come in later stages.
- The supplied project is Python regardless of the language you use to implement your agent.
- For more background, see the [LSP specification][lsp] and [Claude Code's LSP tool][claude-lsp].

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[lsp]: https://microsoft.github.io/language-server-protocol/
[claude-lsp]: https://code.claude.com/docs/en/tools-reference#lsp-tool-behavior
