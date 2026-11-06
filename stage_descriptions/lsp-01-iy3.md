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
initialization. Its API for your language is:

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

### Notes

{{#lang_is_c}}
- `lsp_from_environment` initializes an `LSPClient` value. Release it with `lsp_deinit` when the agent is finished with the connection.
{{/lang_is_c}}
{{#lang_is_zig}}
- Release the client with `deinit` when the agent is finished with the connection.
{{/lang_is_zig}}

- `LSP client connected` is a startup log on standard error. Standard output is reserved for the model's answer.
- Only `goToDefinition` is offered for now. Reference lookup and a handler that contacts the language server come in later stages.
- The supplied project is Python regardless of the language you use to implement your agent.
- For more background, see the [LSP specification][lsp] and [Claude Code's LSP tool][claude-lsp].

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[lsp]: https://microsoft.github.io/language-server-protocol/
[claude-lsp]: https://code.claude.com/docs/en/tools-reference#lsp-tool-behavior
[client-c]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/c/code/src/lsp_client.h
[client-cpp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/cpp/code/src/lsp_client.hpp
[client-csharp]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/csharp/code/src/LSPClient.cs
[client-go]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/go/code/app/lsp_client.go
[client-java]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/java/code/src/main/java/LSPClient.java
[client-javascript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/javascript/code/app/lsp_client.js
[client-python]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/python/code/app/lsp_client.py
[client-rust]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/rust/code/src/lsp_client.rs
[client-typescript]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/typescript/code/app/lsp_client.ts
[client-zig]: https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/zig/code/src/lsp_client.zig
