In this extension, you'll give your agent tools to find function definitions and
affected callers, then use those tools to change code across files.

In this stage, you'll initialize the supplied LSP client.

### Why LSP?

Your agent can already read files, search with Bash, and write changes. Finding
the right code can still mean searching for a name and following its imports.
The **[Language Server Protocol (LSP)][lsp]** lets your agent ask a language server
questions such as "Where is this function defined?" A language server analyzes
code to understand relationships between definitions, imports, and uses.

In the supplied [invoice project][example], `checkout.py` contains:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

Without LSP, the agent searches for `invoice_total` and finds the call and
import above. It must read the import to work out that `invoice_total` is an
alias for `total`, then open `pricing.py` and find that function:

```python
def total(price: int, quantity: int) -> int:
    return price * quantity
```

With LSP, the agent sends a definition lookup request to the language server,
identifying the `invoice_total` call by its file, line, and character position.
The server follows the import and returns the location of `total` in
`pricing.py`. The agent then uses its Read tool to open that file and inspect
the function. **LSP locates the definition; Read retrieves the code.**

### Connect the supplied client

Your agent communicates with the language server through the supplied LSP client.
During course tests, the environment starts the server and handles message
delivery for you. You don't need to install or launch a server.

The client is included in your starter repository. Initialize it once during
startup, before your first model request, and keep it available to your agent's
tool handlers.

{{#lang_is_c}}

The supplied client is in `src/lsp_client.h`. At the top of your agent's C source, add:

```c
#include "lsp_client.h"
```

Inside `main`, after your existing `curl_global_init` and before the agent loop:

```c
LSPClient lsp;
if (!lsp_init(&lsp)) return 1;
```

Call `lsp_deinit(&lsp)` after the agent loop, before your existing libcurl
cleanup. `lsp_call` still sends requests through the supplied connection.

{{/lang_is_c}}

{{#lang_is_cpp}}

The supplied client is in `src/lsp_client.hpp`. At the top of your C++ source, add:

```cpp
#include "lsp_client.hpp"
```

Before the agent loop:

```cpp
LSPClient lsp;
```

The client uses the starter's existing CPR and nlohmann JSON dependencies.
Constructor, HTTP, and JSON errors propagate as exceptions. Handle them with
your agent's existing exception handling.

{{/lang_is_cpp}}

{{#lang_is_csharp}}

The supplied client is in `src/LSPClient.cs`. The starter includes `.cs` files under `src/`
automatically. No client import is needed. In your top-level startup code or an
async startup method:

```csharp
var lsp = await LSPClient.CreateAsync();
```

`CreateAsync` initializes the client. Await it before the agent loop. Handle
exceptions with your agent's existing error handling.

{{/lang_is_csharp}}

{{#lang_is_go}}

The supplied client is in `app/lsp_client.go`, in the same `package main` as your
agent. No client import is needed. Add `log` to your imports, then place this
inside your startup function:

```go
lsp, err := NewLSPClient()
if err != nil {
    log.Fatal(err)
}
_ = lsp // Used by the LSP handler in Stage 3.
```

Remove `_ = lsp` once your LSP handler uses the client. Run the whole package
with `go run ./app`, rather than compiling only `app/main.go`.

{{/lang_is_go}}

{{#lang_is_java}}

The supplied client is in `src/main/java/LSPClient.java`. It shares the starter's default package with
`Main`, so no client import is needed. Inside your startup method:

```java
var lsp = new LSPClient();
```

Construction and `call` throw checked exceptions: catch them with your existing
error handling, or declare `throws Exception` on your startup method.

{{/lang_is_java}}

{{#lang_is_javascript}}

The supplied client is in `app/lsp_client.js`. From another file in `app/`, import the client and await
initialization at module scope or inside your async startup function:

```javascript
import { LSPClient } from "./lsp_client.js";

const lsp = await LSPClient.create();
```

{{/lang_is_javascript}}

{{#lang_is_python}}

The supplied client is in `app/lsp_client.py`. In your agent's Python module:

```python
from app.lsp_client import LSPClient

lsp = LSPClient()
```

Failed initialization or calls raise exceptions.

{{/lang_is_python}}

{{#lang_is_rust}}

The supplied client is in `src/lsp_client.rs`. At the top level of `src/main.rs`, add:

```rust
mod lsp_client;
use lsp_client::LspClient;
```

Inside your existing `main` or startup function:

```rust
let lsp = LspClient::new()?;
```

The type is `LspClient`. Both `new` and `call` return a `Result`. The `?`
operator propagates errors from a function returning a compatible `Result`,
such as the starter's `Result<(), Box<dyn std::error::Error>>`. If your startup
function returns another type, handle these results explicitly instead.

{{/lang_is_rust}}

{{#lang_is_typescript}}

The supplied client is in `app/lsp_client.ts`. From another file in `app/`, import the client and await
initialization at module scope or inside your async startup function:

```typescript
import { LSPClient } from "./lsp_client.ts";

const lsp = await LSPClient.create();
```

{{/lang_is_typescript}}

{{#lang_is_zig}}

The supplied client is in `src/lsp_client.zig`. At the top of `src/main.zig`, add:

```zig
const LSPClient = @import("lsp_client.zig").LSPClient;
```

Inside `main(init: std.process.Init) !void`, after the starter's `allocator` and
`io` declarations:

```zig
var lsp = try LSPClient.init(
    allocator, io, init.environ_map.get("CODECRAFTERS_LSP_URL"));
defer lsp.deinit();
```

`init` and `call` return error unions, so use `try` from a function returning an
error union, as the starter does. Keep the client alive until after the agent
loop. The deferred cleanup above runs on exit.

{{/lang_is_zig}}

### Tests

The tester supplies the invoice project in your agent's working directory and
runs:

```bash
$ ./your_program.sh -p "Use only Read to inspect checkout.py and pricing.py. Explain how checkout uses the pricing function."
```

Your agent must initialize the client before its first model request. The tester
checks that the client connected successfully. You don't need to advertise an
LSP tool yet.

If the client file is missing or outdated, see
[troubleshooting older repositories][client-troubleshooting].

Optional: [run locally][local-run].

After passing this stage, your agent initializes the client successfully before
starting its model conversation. Next, you'll advertise the `LSP` tool so the
model knows it can request code navigation.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[client-troubleshooting]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/README.md#troubleshooting-older-repositories
[local-run]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/advanced_usage.md#run-with-your-own-server
[lsp]: https://microsoft.github.io/language-server-protocol/
