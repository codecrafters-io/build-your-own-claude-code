In this stage, you'll implement `findReferences` to find the callers affected by an API change.

### Which callers need updating?

Definition lookup took you from a call to its implementation. Reference lookup
starts at that implementation and discovers where it's used.

Suppose you want to change `pricing.total` from returning integer cents to
returning an object: `500` would become `{"cents": 500}`. Before editing it,
you need to find the callers that depend on its current return value.

Checkout imports the function as `invoice_total` and returns its result:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

Reporting uses the original name and adds the results of two calls:

```python
from pricing import total


def report_total() -> int:
    return total(250, 2) + total(100, 1)
```

After that change, checkout would return an object and reporting would try to
add two objects. The unrelated `total` in `preview.py` should stay unchanged.

Searching for `total` also finds unrelated functions and comments. A
[references request][references] asks the language server for locations tied to
`pricing.total`, including uses through an alias.

### Add references to your LSP tool

Extend the existing LSP tool's operation enum to
`["goToDefinition", "findReferences"]`. Keep definition lookup available: the
model needs both ways to navigate. The file path, line, and character arguments
stay the same because both operations ask about a symbol at a position.
Replace the tool's description with:

```text
Find where a symbol at a given file position is defined or referenced. Input line and character are one-based UTF-16; returned ranges are zero-based. Add 1 to each returned coordinate before reusing it as input.
```

Replace the LSP guidance you added to your system prompt when you advertised the tool:

```text
Use LSP to find where a symbol is defined or referenced.
```

In your handler, route `findReferences` to a references request. Reuse document
opening, file URIs, position conversion, and tool-result handling from definition lookup.

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

Resolve and read `pricing.py`, and send `didOpen` if its URI isn't already open,
just as you did for definition lookup. Use the saved extension mapping for its
language ID and wait for the notification call to complete before requesting.
Opening `checkout.py` in an earlier lookup doesn't open `pricing.py`, because your record
of open documents is per URI.

Send the helper action `request` with the complete payload below, using your
language's client-call pattern from definition lookup. Convert the one-based tool position
1:5 to the zero-based LSP position 0:4:

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

The method is now `textDocument/references`. Its `context.includeDeclaration`
setting asks the server to include the symbol's own declaration along with its
uses, so the answer can contain the definition in `pricing.py` too. Keep this
setting fixed to `true` in your handler. The model doesn't need another argument
to choose it.

### Understand the returned locations

For the full invoice project under `/project`, the supplied test server returns:

```json
[
  {
    "uri": "file:///project/pricing.py",
    "range": {
      "start": {"line": 0, "character": 4},
      "end": {"line": 0, "character": 9}
    }
  },
  {
    "uri": "file:///project/checkout.py",
    "range": {
      "start": {"line": 0, "character": 20},
      "end": {"line": 0, "character": 25}
    }
  },
  {
    "uri": "file:///project/checkout.py",
    "range": {
      "start": {"line": 4, "character": 11},
      "end": {"line": 4, "character": 24}
    }
  },
  {
    "uri": "file:///project/reports.py",
    "range": {
      "start": {"line": 0, "character": 20},
      "end": {"line": 0, "character": 25}
    }
  },
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

Each entry has a file URI and a zero-based range, just like a definition location.
The response includes the declaration in `pricing.py`, the import and aliased
call in `checkout.py`, and the import and two calls in `reports.py`. Several entries
can refer to the same file because they identify different occurrences.

These are reference locations, so not every entry is a function call. The model
uses Read to inspect the returned files and decide how their uses depend on the
current return value. Returning a location doesn't open that document in the
language server, and reading it with Read doesn't send `didOpen` either.

Your handler passes through the server's answer rather than reconstructing
locations or filtering them by spelling.

### Return the answer to the model

Serialize the result as the tool message's `content` and use the matching
`tool_call_id`, as you did for definition lookup. If your client already returns JSON
text, use that text directly. Return every location, preserving the array order,
URIs, and ranges. Don't collapse several references in one file into a single
entry or convert the result positions to one-based.

An empty array means the server returned no reference locations. Pass it through
unchanged, using the same tool-result handling as a nonempty array.

### Tests

The tester will create the invoice project and execute your program like this:

```bash
$ ./your_program.sh -p "Use LSP findReferences on pricing.py at line 1, character 5. Identify every affected caller before changing its return type. Preserve the returned locations; preview.total and comments are unrelated."
<the model's list of the affected callers>
```

The tester will verify that:

- Your program sends `textDocument/references` for `pricing.py` at position 0:4, with `includeDeclaration` set to `true`
- The tool result contains every location the server returned, with the matching `tool_call_id`
- Your program exits with code `0`

The tester will also run this prompt on a project without `reports.py`, and against a server that returns an empty array.

### Notes

- Other language servers can represent aliased references differently. Pyright, for example, returns checkout's import of `total` but not the `invoice_total` call. Pass through whatever the server returns, and the model can read `checkout.py` to follow the alias to the call.

[references]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references
