In this stage, you'll initialize the supplied LSP client and log when it connects.

### Why LSP?

Your agent can already read files, search with Bash, and write changes. Finding
the right code can still mean searching for a name and following its imports.

A language server is a program that reads a project's code and knows where each
function is defined and where it is used. Editors like VS Code run one in the
background to answer questions such as "Where is this function defined?" Your
agent can ask the same questions using the **[Language Server Protocol (LSP)][lsp]**.

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

Instead, the agent can ask the language server where `invoice_total` is
defined. The server follows the import and returns the location of `total` in
`pricing.py` in a single request.

### Connect the supplied client

We've written an LSP client for your language. It connects to the language
server and sends it your agent's requests, so you don't write that part
yourself. The tester starts the language server, and the client connects to it.

Create the client once at startup, before your first model request. Keep it,
because later stages call it from your tool handlers.

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
auto lsp_client = LSPClient::from_environment(); // std::nullopt when not configured
if (lsp_client) {
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
let lsp_client = LspClient::from_environment()?; // None when not configured
if lsp_client.is_some() {
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
var lsp_client = try LSPClient.fromEnvironment(allocator, io, init.environ_map); // null when not configured
defer if (lsp_client) |*lsp| lsp.deinit();
if (lsp_client != null) {
    std.debug.print("LSP client connected\n", .{});
}
```

[client-zig]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/zig/code/src/lsp_client.zig

{{/lang_is_zig}}

### Tests

The tester will create the invoice project in your program's working directory and execute your program like this:

```bash
$ ./your_program.sh -p "Use only Read to inspect checkout.py and pricing.py. Explain how checkout uses the pricing function."
LSP client connected
<the model's explanation of how checkout uses pricing.total>
```

The tester will verify that:

- Your program connects the supplied LSP client before its first model request
- Read returns the complete contents of `checkout.py` and `pricing.py` to the model
- Your program exits with code `0`

### Notes

- This stage only connects the client. You'll send lookups to the language server in later stages.

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[lsp]: https://microsoft.github.io/language-server-protocol/
