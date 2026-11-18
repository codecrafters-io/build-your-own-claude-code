In this stage, you'll connect the supplied language-server client and advertise
an `LSP` tool. This gives your agent access to the code analysis behind editor
features such as "Go to definition". The tool will return a placeholder for now.

### Why LSP?

Your agent can already read files, edit them, and run commands. Finding the
right code to change takes more than searching for a name. A project can have
several functions called `total`, and an import can give one of them an alias.

A language server is a program that analyzes source code. It can connect a
function call to its definition and report problems such as type errors. The
Language Server Protocol (LSP) defines the messages an editor or your agent
uses to ask for that analysis.

Across this extension, you'll give the model enough information to change a
function's return type and repair its callers across files. You'll start with
tool registration, then add navigation, keep the server up to date after edits,
and return error reports to the model. Your existing agent loop and `Read`,
`Write`, and `Bash` tools provide the starting point.

### Expected behavior

The tester starts the language server and supplies its connection settings.
The client handles communication with it, so you can focus on connecting the
analysis to your agent. Initialize the client before the first model request
and keep it available throughout the run. When connected, every model request
must advertise the `LSP` tool below alongside your existing tools. When
unconfigured, continue with the existing tools alone.

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

The arguments identify a symbol, such as a function name, at a particular spot
in a file. That position distinguishes uses of functions with the same name.
The [invoice project][example] contains this code at the start of `checkout.py`:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

The model points at the `i` in the return statement's `invoice_total` with line
5, character 12. Both count from 1. For the ASCII text shown here, each character
occupies one position. We'll look at the server's position format in the next
stage.

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

Your starter project includes the client below. If it's missing, download it
from the linked source and save it at the shown path. The client fetches its
configuration during initialization. Its API for your language is:

{{#lang_is_c}}

The supplied client is [lsp_client.h](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/c/code/src/lsp_client.h), at `src/lsp_client.h`.
Its initialization call is `lsp_from_environment(&lsp)`. `1` means connected, `0` unconfigured, and `-1` an initialization error.

{{/lang_is_c}}

{{#lang_is_cpp}}

The supplied client is [lsp_client.hpp](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/cpp/code/src/lsp_client.hpp), at `src/lsp_client.hpp`.
Its initialization call is `LSPClient::from_environment()`. It returns an optional client, with `std::nullopt` when unconfigured.

{{/lang_is_cpp}}

{{#lang_is_csharp}}

The supplied client is [LSPClient.cs](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/csharp/code/src/LSPClient.cs), at `src/LSPClient.cs`.
Its initialization call is `await LSPClient.FromEnvironmentAsync()`. It returns a client, or `null` when unconfigured.

{{/lang_is_csharp}}

{{#lang_is_go}}

The supplied client is [lsp_client.go](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/go/code/app/lsp_client.go), at `app/lsp_client.go`.
Its initialization call is `LSPClientFromEnvironment()`. It returns a client and an error. The client is `nil` when unconfigured.

{{/lang_is_go}}

{{#lang_is_java}}

The supplied client is [LSPClient.java](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/java/code/src/main/java/LSPClient.java), at `src/main/java/LSPClient.java`.
Its initialization call is `LSPClient.fromEnvironment()`. It returns a client, or `null` when unconfigured. Initialization can throw checked exceptions.

{{/lang_is_java}}

{{#lang_is_javascript}}

The supplied client is [lsp_client.js](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/javascript/code/app/lsp_client.js), at `app/lsp_client.js`.
Its initialization call is `await LSPClient.fromEnvironment()`. It returns a client, or `null` when unconfigured.

{{/lang_is_javascript}}

{{#lang_is_python}}

The supplied client is [lsp_client.py](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/python/code/app/lsp_client.py), at `app/lsp_client.py`.
Its initialization call is `LSPClient.from_environment()`. It returns a client, or `None` when unconfigured.

{{/lang_is_python}}

{{#lang_is_rust}}

The supplied client is [lsp_client.rs](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/rust/code/src/lsp_client.rs), at `src/lsp_client.rs`.
Its initialization call is `LspClient::from_environment()`. It returns a `Result` holding an optional client, with `None` when unconfigured.

{{/lang_is_rust}}

{{#lang_is_typescript}}

The supplied client is [lsp_client.ts](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/typescript/code/app/lsp_client.ts), at `app/lsp_client.ts`.
Its initialization call is `await LSPClient.fromEnvironment()`. It returns a client, or `null` when unconfigured.

{{/lang_is_typescript}}

{{#lang_is_zig}}

The supplied client is [lsp_client.zig](https://raw.githubusercontent.com/codecrafters-io/build-your-own-claude-code/main/starter_templates/zig/code/src/lsp_client.zig), at `src/lsp_client.zig`.
Its initialization call is `LSPClient.fromEnvironment(allocator, io, init.environ_map)`. It returns an error union holding an optional client, with `null` when unconfigured.

{{/lang_is_zig}}

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP goToDefinition on checkout.py at line 5, character 12. If navigation is not implemented yet, report the tool response without retrying."
<the model's report of the tool response>
```

Write the startup log `LSP client connected` to standard error after connecting.
Standard output remains reserved for the model's answer.

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

- Only `goToDefinition` is offered for now. Reference lookup and a handler that contacts the language server come in later stages.
- The supplied project is Python regardless of the language you use to implement your agent.
- For more background, see the [LSP specification][lsp] and [Claude Code's LSP tool][claude-lsp].

[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
[lsp]: https://microsoft.github.io/language-server-protocol/
[claude-lsp]: https://code.claude.com/docs/en/tools-reference#lsp-tool-behavior
