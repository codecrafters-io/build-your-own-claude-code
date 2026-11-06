In this stage, you'll implement `findReferences` to find the callers affected by an API change.

### Why find references?

Changing a function's return type can break callers in other files. In the
[invoice project][example], checkout imports `pricing.total` as `invoice_total`,
while reporting calls it by its original name. Reference lookup finds uses tied
to that definition, including aliases, while excluding the unrelated
`preview.total` and comments that merely mention the name.

### Expected tool result

Each location returned by the server must reach the model with its relative
file path and one-based start line and character. Several locations in one
file remain separate references. For the full invoice project, a result can
look like this:

```text
Found 6 references across 3 files:

pricing.py:
  Line 1:5

checkout.py:
  Line 1:21
  Line 5:12

reports.py:
  Line 1:21
  Line 5:12
  Line 5:28
```

Return the result with the matching `tool_call_id`. When the server returns an
empty array, report that no references were found, for example `No references found.`

### Tool interface

The `LSP` tool must advertise both `goToDefinition` and `findReferences`.
Both operations identify a symbol with `filePath`, `line`, and `character`,
using the same one-based input positions. The model should understand that it
can use the tool to find definitions and references.

### Ask where the function is used

The model starts at the definition of `pricing.total`:

```json
{
  "operation": "findReferences",
  "filePath": "pricing.py",
  "line": 1,
  "character": 5
}
```

Line 1, character 5 points to the `t` in `def total`. This tells the server which
function's references to find, rather than asking it to match every occurrence of
the word `total`.

The queried file must be open before the request, following the URI and position
rules from definition lookup. Opening `checkout.py` in an earlier lookup doesn't
open `pricing.py`.

The corresponding `textDocument/references` request uses the zero-based
position 0:4 and the client's `request` action:

```json
{
  "method": "textDocument/references",
  "params": {
    "textDocument": { "uri": "file:///project/pricing.py" },
    "position": { "line": 0, "character": 4 },
    "context": { "includeDeclaration": true }
  }
}
```

Its `context.includeDeclaration` setting asks the server to include the symbol's
own declaration along with its uses. This stage requires `includeDeclaration`
to be `true`.

### Understanding reference locations

The server returns an array of file URIs and zero-based ranges. For example,
these two locations identify separate calls in `reports.py`:

```json
[
  {
    "uri": "file:///project/reports.py",
    "range": {
      "start": {"line": 4, "character": 11},
      "end": {"line": 4, "character": 16}
    }
  },
  {
    "uri": "file:///project/reports.py",
    "range": {
      "start": {"line": 4, "character": 27},
      "end": {"line": 4, "character": 32}
    }
  }
]
```

The full result also includes imports, the declaration in `pricing.py`, and
uses in `checkout.py`. Reference locations can describe any of these; each
must remain represented in the tool result.

### Tests

The tester will create the [invoice project][example] and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP findReferences on pricing.py at line 1, character 5, and list the callers that a change to pricing.total's return type would affect. Don't change any code. Preserve the returned locations; preview.total and comments are unrelated."
<the model's list of the affected callers>
```

The tester will verify that:

- Your program sends `textDocument/references` for `pricing.py` at position 0:4, with `includeDeclaration` set to `true`
- The tool result names every location the server returned, each with its file and 1-based line and character, with the matching `tool_call_id`
- Your program exits with code `0`

The tester will also run this prompt against a server that returns an empty array.

### Notes

- See the [references request specification][references] for the protocol details.
- Other language servers can represent aliased references differently. Pyright, for example, returns checkout's import of `total` but not the `invoice_total` call. Return whatever the server finds, and the model can read `checkout.py` to follow the alias to the call.

[references]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
