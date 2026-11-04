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

The language server is a separate program that analyzes code and answers
questions about definitions and references. It stays running across requests,
so your agent can query it repeatedly. The supplied LSP client sends your
agent's requests to the server and returns its responses.

LSP course tests provide the server connection automatically. You don't need to
configure it yourself.

The client is included in your starter repository. Use the setup call below once
during startup, before your first model request, and keep the client for your
tool handlers. You'll connect the model's LSP calls to this client in later
stages.

{{#lang_is_c}}

The supplied client is in `src/lsp_client.h`. If it is missing or outdated,
[download the current client][client-c] and save it to that path.

At the top of your agent's C source, add:

```c
#include "lsp_client.h"
```

Inside `main`, after your existing `curl_global_init` and before the agent loop:

```c
LSPClient lsp;
int lsp_status = lsp_from_environment(&lsp);
if (lsp_status < 0) return 1;
```

`lsp_status` is 1 when connected and 0 when unconfigured. Use the client only
when it is 1. Call `lsp_deinit(&lsp)` after the agent loop, before your existing
libcurl cleanup. `lsp_call` still sends requests through the supplied connection.

[client-c]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/c/code/src/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

The supplied client is in `src/lsp_client.hpp`. If it is missing or outdated,
[download the current client][client-cpp] and save it to that path.

At the top of your C++ source, add:

```cpp
#include "lsp_client.hpp"
```

Before the agent loop:

```cpp
auto lsp_client = LSPClient::from_environment();
```

The factory returns `std::optional<LSPClient>`. Use `if (lsp_client)` to check
whether LSP is configured. The client uses the starter's existing CPR and
nlohmann JSON dependencies. HTTP and JSON errors propagate as exceptions;
handle them with your agent's existing exception handling.

[client-cpp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/cpp/code/src/lsp_client.hpp

{{/lang_is_cpp}}

{{#lang_is_csharp}}

The supplied client is in `src/LSPClient.cs`. If it is missing or outdated,
[download the current client][client-csharp] and save it to that path.

The starter includes `.cs` files under `src/`
automatically. No client import is needed. In your top-level startup code or an
async startup method:

```csharp
var lsp = await LSPClient.FromEnvironmentAsync();
```

The result is `LSPClient?`, with `null` meaning no connection is configured.
Await initialization before the agent loop. Handle exceptions with your agent's
existing error handling.

[client-csharp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/csharp/code/src/LSPClient.cs

{{/lang_is_csharp}}

{{#lang_is_go}}

The supplied client is in `app/lsp_client.go`. If it is missing or outdated,
[download the current client][client-go] and save it to that path.

The client shares the same `package main` as your agent. No client import is
needed. Add `log` to your imports, then place this inside your startup function:

```go
lsp, err := LSPClientFromEnvironment()
if err != nil {
    log.Fatal(err)
}
_ = lsp // Used by the LSP handler in Stage 3.
```

The client is `nil` when no connection is configured. Remove `_ = lsp` once your
LSP handler uses the client. Run the whole package with `go run ./app`, rather
than compiling only `app/main.go`.

[client-go]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/go/code/app/lsp_client.go

{{/lang_is_go}}

{{#lang_is_java}}

The supplied client is in `src/main/java/LSPClient.java`. If it is missing or outdated,
[download the current client][client-java] and save it to that path.

It shares the starter's default package with
`Main`, so no client import is needed. Inside your startup method:

```java
var lsp = LSPClient.fromEnvironment();
```

The factory returns `null` when no connection is configured. Initialization and
`call` throw checked exceptions: catch them with your existing error handling,
or declare `throws Exception` on your startup method.

[client-java]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/java/code/src/main/java/LSPClient.java

{{/lang_is_java}}

{{#lang_is_javascript}}

The supplied client is in `app/lsp_client.js`. If it is missing or outdated,
[download the current client][client-javascript] and save it to that path.

From another file in `app/`, import the client and await
initialization at module scope or inside your async startup function:

```javascript
import { LSPClient } from "./lsp_client.js";

const lsp = await LSPClient.fromEnvironment();
```

The factory returns `null` when no connection is configured.

[client-javascript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/javascript/code/app/lsp_client.js

{{/lang_is_javascript}}

{{#lang_is_python}}

The supplied client is in `app/lsp_client.py`. If it is missing or outdated,
[download the current client][client-python] and save it to that path.

In your agent's Python module:

```python
from app.lsp_client import LSPClient

lsp = LSPClient.from_environment()
```

The factory returns `None` when no connection is configured. Failed
initialization or calls raise exceptions.

[client-python]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/python/code/app/lsp_client.py

{{/lang_is_python}}

{{#lang_is_rust}}

The supplied client is in `src/lsp_client.rs`. If it is missing or outdated,
[download the current client][client-rust] and save it to that path.

At the top level of `src/main.rs`, add:

```rust
mod lsp_client;
use lsp_client::LspClient;
```

Inside your existing `main` or startup function:

```rust
let lsp_client = LspClient::from_environment()?;
```

The result is `Option<LspClient>`, with `None` meaning no connection is configured.
Both `from_environment` and `call` return a `Result`. The `?` operator propagates
errors from a function returning a compatible `Result`, such as the starter's
`Result<(), Box<dyn std::error::Error>>`. If your startup function returns another
type, handle these results explicitly instead.

[client-rust]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/rust/code/src/lsp_client.rs

{{/lang_is_rust}}

{{#lang_is_typescript}}

The supplied client is in `app/lsp_client.ts`. If it is missing or outdated,
[download the current client][client-typescript] and save it to that path.

From another file in `app/`, import the client and await
initialization at module scope or inside your async startup function:

```typescript
import { LSPClient } from "./lsp_client.ts";

const lsp = await LSPClient.fromEnvironment();
```

The factory returns `null` when no connection is configured.

[client-typescript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/typescript/code/app/lsp_client.ts

{{/lang_is_typescript}}

{{#lang_is_zig}}

The supplied client is in `src/lsp_client.zig`. If it is missing or outdated,
[download the current client][client-zig] and save it to that path.

At the top of `src/main.zig`, add:

```zig
const LSPClient = @import("lsp_client.zig").LSPClient;
```

Inside `main(init: std.process.Init) !void`, after the starter's `allocator` and
`io` declarations:

```zig
var lsp_client = try LSPClient.fromEnvironment(allocator, io, init.environ_map);
defer if (lsp_client) |*lsp| lsp.deinit();
```

The result is `?LSPClient`, with `null` meaning no connection is configured.
`fromEnvironment` and `call` return error unions, so use `try` from a function
returning an error union, as the starter does. Keep the client alive until after
the agent loop. The deferred cleanup above runs on exit.

[client-zig]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/zig/code/src/lsp_client.zig

{{/lang_is_zig}}

### Tests

Run `codecrafters test` to verify your connection. The tester supplies the
invoice project in your agent's working directory and runs:

```bash
$ ./your_program.sh -p "Use only Read to inspect checkout.py and pricing.py. Explain how checkout uses the pricing function."
```

Your agent must initialize the client before its first model request. The tester
checks that the client connected successfully. You don't need to advertise an
LSP tool yet.

Optional: [run LSP locally][local-run].

After passing this stage, your agent initializes the client successfully before
starting its model conversation. Next, you'll advertise the `LSP` tool so the
model knows it can request code navigation.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[local-run]: https://github.com/codecrafters-io/build-your-own-claude-code/blob/main/extension_helpers/advanced_usage.md#run-with-your-own-server
[lsp]: https://microsoft.github.io/language-server-protocol/
