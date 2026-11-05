In this extension, you'll give your agent tools to find function definitions and
affected callers, then use those tools to change code across files.

In this stage, you'll initialize the supplied LSP client and log when it connects.

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

The supplied LSP client sends your agent's requests to the language server and
returns its responses. The server runs as a separate program and stays running
across requests.

LSP course tests provide the server connection automatically. You don't need to
configure it yourself.

The client is included in your starter repository. Use the setup call below once
during startup, before your first model request, and keep the client for your
tool handlers.

After initialization, print `LSP client connected` to standard error if you
received a client. If no connection is configured, continue without printing the
message. Keep standard output for your agent's answer.

{{#lang_is_c}}

The supplied client is in `src/lsp_client.h`. You can
[download the latest copy here][client-c] and save it to that path.

At the top of your agent's C source, add:

```c
#include "lsp_client.h"
```

Inside `main`, after your existing `curl_global_init` and before the agent loop:

```c
LSPClient lsp;
int lsp_status = lsp_from_environment(&lsp);
if (lsp_status < 0) return 1;
if (lsp_status == 1) {
    fprintf(stderr, "LSP client connected\n");
}
```

`lsp_status` is 1 when connected and 0 when unconfigured. Use the client only
when it is 1. Call `lsp_deinit(&lsp)` after the agent loop, before your existing
libcurl cleanup. `lsp_call` still sends requests through the supplied connection.

[client-c]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/c/code/src/lsp_client.h

{{/lang_is_c}}

{{#lang_is_cpp}}

The supplied client is in `src/lsp_client.hpp`. You can
[download the latest copy here][client-cpp] and save it to that path.

At the top of your C++ source, add:

```cpp
#include "lsp_client.hpp"
```

Before the agent loop:

```cpp
auto lsp_client = LSPClient::from_environment();
if (lsp_client) {
    std::cerr << "LSP client connected\n";
}
```

The factory returns `std::optional<LSPClient>`. Use `if (lsp_client)` to check
whether LSP is configured. The client uses the starter's existing CPR and
nlohmann JSON dependencies. HTTP and JSON errors propagate as exceptions;
handle them with your agent's existing exception handling.

[client-cpp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/cpp/code/src/lsp_client.hpp

{{/lang_is_cpp}}

{{#lang_is_csharp}}

The supplied client is in `src/LSPClient.cs`. You can
[download the latest copy here][client-csharp] and save it to that path.

The starter includes `.cs` files under `src/`
automatically. No client import is needed. In your top-level startup code or an
async startup method:

```csharp
var lsp = await LSPClient.FromEnvironmentAsync();
if (lsp is not null) {
    Console.Error.WriteLine("LSP client connected");
}
```

The result is `LSPClient?`, with `null` meaning no connection is configured.
Await initialization before the agent loop. Handle exceptions with your agent's
existing error handling.

[client-csharp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/csharp/code/src/LSPClient.cs

{{/lang_is_csharp}}

{{#lang_is_go}}

The supplied client is in `app/lsp_client.go`. You can
[download the latest copy here][client-go] and save it to that path.

The client shares the same `package main` as your agent. No client import is
needed. Add `log` to your imports, then place this inside your startup function:

```go
lsp, err := LSPClientFromEnvironment()
if err != nil {
    log.Fatal(err)
}
if lsp != nil {
    log.Print("LSP client connected")
}
```

The client is `nil` when no connection is configured. Run the whole package with
`go run ./app`, rather than compiling only `app/main.go`.

[client-go]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/go/code/app/lsp_client.go

{{/lang_is_go}}

{{#lang_is_java}}

The supplied client is in `src/main/java/LSPClient.java`. You can
[download the latest copy here][client-java] and save it to that path.

It shares the starter's default package with
`Main`, so no client import is needed. Inside your startup method:

```java
var lsp = LSPClient.fromEnvironment();
if (lsp != null) {
    System.err.println("LSP client connected");
}
```

The factory returns `null` when no connection is configured. Initialization and
`call` throw checked exceptions: catch them with your existing error handling,
or declare `throws Exception` on your startup method.

[client-java]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/java/code/src/main/java/LSPClient.java

{{/lang_is_java}}

{{#lang_is_javascript}}

The supplied client is in `app/lsp_client.js`. You can
[download the latest copy here][client-javascript] and save it to that path.

From another file in `app/`, import the client and await
initialization at module scope or inside your async startup function:

```javascript
import { LSPClient } from "./lsp_client.js";

const lsp = await LSPClient.fromEnvironment();
if (lsp !== null) {
    console.error("LSP client connected");
}
```

The factory returns `null` when no connection is configured.

[client-javascript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/javascript/code/app/lsp_client.js

{{/lang_is_javascript}}

{{#lang_is_python}}

The supplied client is in `app/lsp_client.py`. You can
[download the latest copy here][client-python] and save it to that path.

In your agent's Python module:

```python
import sys

from app.lsp_client import LSPClient

lsp = LSPClient.from_environment()
if lsp is not None:
    print("LSP client connected", file=sys.stderr)
```

The factory returns `None` when no connection is configured. Failed
initialization or calls raise exceptions.

[client-python]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/python/code/app/lsp_client.py

{{/lang_is_python}}

{{#lang_is_rust}}

The supplied client is in `src/lsp_client.rs`. You can
[download the latest copy here][client-rust] and save it to that path.

At the top level of `src/main.rs`, add:

```rust
mod lsp_client;
use lsp_client::LspClient;
```

Inside your existing `main` or startup function:

```rust
let lsp_client = LspClient::from_environment()?;
if lsp_client.is_some() {
    eprintln!("LSP client connected");
}
```

The result is `Option<LspClient>`, with `None` meaning no connection is configured.

[client-rust]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/rust/code/src/lsp_client.rs

{{/lang_is_rust}}

{{#lang_is_typescript}}

The supplied client is in `app/lsp_client.ts`. You can
[download the latest copy here][client-typescript] and save it to that path.

From another file in `app/`, import the client and await
initialization at module scope or inside your async startup function:

```typescript
import { LSPClient } from "./lsp_client.ts";

const lsp = await LSPClient.fromEnvironment();
if (lsp !== null) {
    console.error("LSP client connected");
}
```

The factory returns `null` when no connection is configured.

[client-typescript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/typescript/code/app/lsp_client.ts

{{/lang_is_typescript}}

{{#lang_is_zig}}

The supplied client is in `src/lsp_client.zig`. You can
[download the latest copy here][client-zig] and save it to that path.

At the top of `src/main.zig`, add:

```zig
const LSPClient = @import("lsp_client.zig").LSPClient;
```

Inside `main(init: std.process.Init) !void`, after the starter's `allocator` and
`io` declarations:

```zig
var lsp_client = try LSPClient.fromEnvironment(allocator, io, init.environ_map);
defer if (lsp_client) |*lsp| lsp.deinit();
if (lsp_client != null) {
    std.debug.print("LSP client connected\n", .{});
}
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

The connection message helps you confirm startup in the logs. The tester checks
the connection itself, not the message text.

Next, you'll advertise the `LSP` tool so the model knows it can request code
navigation.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[lsp]: https://microsoft.github.io/language-server-protocol/
