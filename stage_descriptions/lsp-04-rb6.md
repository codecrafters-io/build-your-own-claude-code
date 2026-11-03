In this stage, you'll implement `findReferences` to find the callers affected by an API change.
Definition lookup took you from a call to its implementation. Reference lookup
lets you start at that implementation and discover where it's used.

### Which callers need updating?

In a later stage, you'll change `pricing.total` from returning integer cents to
returning an object with a `cents` field. Finding the implementation is only part
of that task: its callers currently expect an integer, so they'll need updating
too. For example, a result of `500` will become `{"cents": 500}`.

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

If you change only `pricing.total`, checkout will return an object where an
integer is expected, and reporting will try to add two objects. Meanwhile,
`preview.py` defines an unrelated `total` that should stay unchanged.

Searching for `total` can find imports, calls, unrelated functions, and comments.
The model can inspect those matches, but it must work out which refer to
`pricing.total`. A [references request][references] asks the language server for
the locations associated with that particular symbol, including uses through an
alias. **LSP locates references; Read gives the model the surrounding code it
needs to understand each use.**

This stage adds that lookup. You'll make the API change later; for now, your
agent should help the model discover the affected code before editing it.

### Add references to your LSP tool

Extend the existing LSP tool's operation enum to
`["goToDefinition", "findReferences"]`. Keep definition lookup available: the
model needs both ways to navigate. The file path, line, and character arguments
stay the same because both operations ask about a symbol at a position.

In your handler, route `findReferences` to a references request. Reuse document
opening, file URIs, position conversion, and tool-result handling from Stage 3.
The new operation changes the question you send, while keeping the same connection
and document tracking.

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
Opening `checkout.py` in an earlier lookup doesn't open `pricing.py`; your record
of open documents is per URI.

Send the helper action `request` with the complete payload below, using your
language's client-call pattern from Stage 3. Convert the one-based tool position
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
setting fixed to `true` in your handler; the model doesn't need another argument
to choose it.

### Understand the returned locations

For the full invoice project under `/project`, the supplied test server returns:

```json
[
  {"uri":"file:///project/reports.py","range":{"start":{"line":4,"character":27},"end":{"line":4,"character":32}}},
  {"uri":"file:///project/reports.py","range":{"start":{"line":4,"character":11},"end":{"line":4,"character":16}}},
  {"uri":"file:///project/reports.py","range":{"start":{"line":0,"character":20},"end":{"line":0,"character":25}}},
  {"uri":"file:///project/checkout.py","range":{"start":{"line":4,"character":11},"end":{"line":4,"character":24}}},
  {"uri":"file:///project/checkout.py","range":{"start":{"line":0,"character":20},"end":{"line":0,"character":25}}},
  {"uri":"file:///project/pricing.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
]
```

Each entry has a file URI and a zero-based range, just like a definition location.
The response includes two calls and an import in `reports.py`, the aliased call
and import in `checkout.py`, and the declaration in `pricing.py`. Several entries
can refer to the same file because they identify different occurrences.

These are reference locations, so not every entry is a function call. The model
uses Read to inspect the returned files and decide how their uses depend on the
current return value. Returning a location doesn't open that document in the
language server, and reading it with Read doesn't send `didOpen` either.

Different servers can represent aliased references differently. For example,
Pyright returns checkout's import of `total`, rather than the `invoice_total`
call. The model can read `checkout.py` to follow the imported alias to the call.
Your handler should pass through the server's answer rather than reconstructing
locations or filtering them by spelling.

### Return the answer to the model

Serialize the result as the tool message's `content` and use the matching
`tool_call_id`, following Stage 3's pattern. If your client already returns JSON
text, use that text directly. Return every location, preserving the array order,
URIs, and ranges. Don't collapse several references in one file into a single
entry or convert the result positions to one-based.

An empty array or `null` means the server returned no reference locations. Pass
that result through unchanged. If a file can't be read, its extension isn't
supported, or a helper call fails, return an error using the same handling as
definition lookup. Keep the agent loop running so the model receives the result
and can decide what to do next.

### Tests

The first case supplies the invoice project without `reports.py` and runs:

```bash
$ ./your_program.sh -p "Use LSP findReferences on pricing.py at line 1, character 5. Identify every affected caller before changing its return type. Preserve the returned locations; preview.total and comments are unrelated."
```

The matching tool result must preserve these locations, with the actual project
URI substituted:

```json
[
  {"uri":"file:///project/checkout.py","range":{"start":{"line":4,"character":11},"end":{"line":4,"character":24}}},
  {"uri":"file:///project/checkout.py","range":{"start":{"line":0,"character":20},"end":{"line":0,"character":25}}},
  {"uri":"file:///project/pricing.py","range":{"start":{"line":0,"character":4},"end":{"line":0,"character":9}}}
]
```

Other cases cover callers across files and an empty result. The tester checks
`includeDeclaration` and every returned location. Together, these cases check
that your handler can return all references, including multiple locations in one
file, without including unrelated text matches. The final explanation can vary.

[references]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references
