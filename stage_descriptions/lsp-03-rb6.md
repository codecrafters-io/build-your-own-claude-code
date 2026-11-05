In this stage, you'll implement `findReferences` to find the callers affected by an API change.

### Which callers need updating?

Definition lookup took you from a call to its implementation. Reference lookup
starts at that implementation and discovers where it's used.

Suppose you want `pricing.total` to return an object instead of a number, so
`500` becomes `{"cents": 500}`. Every caller that uses the number would break.
So before you change the function, you need to find all of its callers.

In the [invoice project][example], `checkout.py` imports the function as
`invoice_total` and returns its result:

```python
from pricing import total as invoice_total


def checkout_total() -> int:
    return invoice_total(250, 2)
```

`reports.py` uses the original name and adds the results of two calls:

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

Add `findReferences` to the LSP tool's `operation` enum, so it becomes
`["goToDefinition", "findReferences"]`. Replace the tool's description with:

```text
Returns the file, line, and character of each place where a symbol is defined or referenced.
```

Replace the LSP guidance you added to your system prompt when you advertised the tool:

```text
Use the LSP tool to find where a symbol is defined or referenced. Lines and characters are 1-based, as in an editor.
```

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

Handle `findReferences` the same way as definition lookup: send `didOpen` if the
file's URI isn't in your set yet, then send the request. Opening `checkout.py` in
an earlier lookup doesn't open `pricing.py`, because the set tracks each URI
separately.

This time the request is [`textDocument/references`][references], at the
zero-based position 0:4. Send it with `call` and `"request"`:

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
own declaration along with its uses, so the answer can contain the definition in
`pricing.py` too. Keep it fixed to `true`. The model doesn't need another
argument to choose it.

### Understand the returned locations

For the full [invoice project][example] under `/project`, the supplied test server returns:

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

Each entry has a file URI and a zero-based range, just like a definition
location. The response includes the declaration in `pricing.py`, the import and
aliased call in `checkout.py`, and the import and two calls in `reports.py`. Not
every entry is a call: imports and the declaration are references too.

### Return the answer to the model

Format each location the same way as for definition lookup: the relative path,
then the start line and character, each plus one. Claude Code groups them by
file:

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

Return the text in a tool message with the model's `tool_call_id`. When the
server returns an empty array, say so, for example `No references found.`

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

- Other language servers can represent aliased references differently. Pyright, for example, returns checkout's import of `total` but not the `invoice_total` call. Return whatever the server finds, and the model can read `checkout.py` to follow the alias to the call.

[references]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references
[example]: https://github.com/codecrafters-io/build-your-own-claude-code/tree/main/extension_designs/lsp_exercise
