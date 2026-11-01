In this stage, you'll return diagnostics after file edits so your agent can
catch and repair its own mistakes.

### Catching the agent's own mistakes

A successful `Write` tells your agent that a file was saved. The change could
still introduce a type error. Now that the server receives edits, it can report
those errors while the agent is working.

For example, suppose `pricing.py` defines a function that expects an integer
price:

```python
def total(price: int, quantity: int) -> int:
    return price * quantity
```

Your agent might accidentally pass a string when editing `checkout.py`:

```python
from pricing import total as invoice_total

amount = invoice_total("250", 2)
```

Here, `invoice_total` is another name for `total`. In Python, `"250" * 2`
produces the text `"250250"`, while `250 * 2` produces the number `500`. The
language server can flag the string argument because the function expects an
integer.

In this stage, you'll return that feedback to the model after `Write`. The model
can then use `Write` again to repair the mistake and receive confirmation that
the type error has cleared. This gives your agent an edit-feedback-repair loop
without needing to run a build to discover this error.

These errors and warnings are called **diagnostics**. They arrive as
[`textDocument/publishDiagnostics`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_publishDiagnostics)
notifications, rather than as responses to a query:

```json
{
  "jsonrpc": "2.0",
  "method": "textDocument/publishDiagnostics",
  "params": {
    "uri": "file:///path/to/project/checkout.py",
    "diagnostics": [
      {
        "range": {
          "start": { "line": 4, "character": 25 },
          "end": { "line": 4, "character": 30 }
        },
        "severity": 1,
        "message": "Argument of type str cannot be assigned to parameter price of type int"
      }
    ]
  }
}
```

### Returning feedback after a write

Update your reader to store the latest list for each URI while continuing to
handle ordinary responses. Each list replaces the previous one. An empty list
clears the old errors.

Before synchronizing a successful `Write`, record which diagnostic publication
you last received for that URI. Send `didChange`, or `didOpen` with the new
contents if the file isn't open. Keep reading messages until a new publication
for that URI arrives, then include its list in the write's tool result:

```json
{ "diagnostics": [] }
```

Dispatch notifications even while waiting for a response. A cached empty list
from before the write isn't feedback about the edit.

The course uses the Write result for feedback. Claude Code can attach it
separately to the conversation. Both let the model act on the findings.

A publication may include `version`. If you advertise
`textDocument.publishDiagnostics.versionSupport: true`, discard versions older
than your document. Accept unversioned reports in arrival order. Use a bounded
wait and return an explicit feedback error if nothing arrives.

### Tests

The tester creates valid `checkout.py` and introduces a known error to make
recovery repeatable. It runs:

```bash
$ ./your_program.sh -p 'Read checkout.py and use LSP goToDefinition on its invoice_total call at line 5, character 12. Use Write to replace integer 250 with string "250". Use the diagnostic feedback to repair the argument with Write, then report whether the error cleared.'
```

The first Write result must contain the error above. Only then does the tester's
model request a repair. The repaired Write must return:

```json
{ "diagnostics": [] }
```

Other cases include unversioned publications, an older version arriving late,
and a server that publishes nothing.

The tester also shows the verified error and repair in its output:

```text
Edit feedback for checkout.py: Argument of type str cannot be assigned to parameter price of type int
Repair feedback for checkout.py: diagnostics []
```

### Notes

- Keep the LSP tool read-only. Diagnostics come from notifications, so don't add
  a `diagnostics` tool operation or invent a protocol request for them.
- The test server publishes once per open or change. Other servers have their
  own timing. An unversioned notification cannot prove which edit it analyzed.
