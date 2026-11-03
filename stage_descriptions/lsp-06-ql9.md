In this stage, you'll use your agent to change an API across several files from a single prompt.
This brings together the connection, definition lookup, references, and edit
synchronization you've built. There is no new LSP operation to implement. Your
agent will use those capabilities alongside Read, Write, and Bash to complete a
larger task.

### One change, several callers

The invoice project currently returns integer cents from `pricing.total`. For
example, `total(250, 2)` returns `500`. You'll ask the agent to change that result
to a dictionary with a `cents` field: `{"cents": 500}`.

Changing the implementation alone isn't enough. `checkout.py` imports it as
`invoice_total` and returns its result, so checkout would start returning a
dictionary instead of an integer. `reports.py` calls it twice as `total` and adds
the results, so reporting would try to add two dictionaries. Both callers need
to extract the integer from the new result. Meanwhile, `preview.py` defines an
unrelated `total` whose behavior should stay unchanged.

This is where the earlier stages work together. Definition lookup follows the
alias to the implementation. References locate its uses across files. Read lets
the model understand each use, and synchronized Write keeps later lookups working
with the edited code. Finally, project tests check whether the whole change
preserves the required behavior.

### Give your agent the task

Use this prompt with your completed agent:

```text
Change pricing.total to return a Price TypedDict with a cents field.
Use LSP to find the implementation and its callers. Update checkout.py and
reports.py so they still return integer cents. Leave preview.total unchanged.
Don't modify test_invoice.py. Run python3 -m unittest -v test_invoice.py.
```

The tester supplies the Python project regardless of your agent's implementation
language. The Python below describes the code your agent will edit.

### Understand the new API

A `TypedDict` describes a dictionary with named, typed fields. Here, `Price`
declares that the result has a `cents` field containing an integer. The value
returned at runtime is an ordinary Python dictionary. The new API is:

```python
from typing import TypedDict


class Price(TypedDict):
    cents: int


def total(price: int, quantity: int) -> Price:
    return {"cents": price * quantity}
```

Each affected call must now read the `cents` field. For example, checkout's call
can return the amount with:

```python
return invoice_total(250, 2)["cents"]
```

Reporting must extract `cents` from each of its two calls before adding the
amounts. Checkout should still return `500`, and reporting should still return
`600`. The change is to pricing's return format; the callers' integer results
remain the same.

The saved code must produce:

```python
>>> from pricing import total
>>> from checkout import checkout_total
>>> from reports import report_total
>>> total(37, 4)
{'cents': 148}
>>> checkout_total()
500
>>> report_total()
600
```


### Let the tools work together

Your agent's existing loop should let the model complete the following work:

1. **Find the implementation.** Use `goToDefinition` on checkout's aliased call
   to locate `pricing.total`.
2. **Locate its uses.** Use `findReferences` on the pricing function. References
   can identify checkout's import rather than its aliased call, so the model uses
   Read to inspect the returned files and find the callers.
3. **Read and edit.** Read each file before its first edit, then use Write to
   change pricing and update its callers. Reads and writes may alternate across
   files; the model doesn't need to read every file before making any edits.
4. **Check the updated code.** Repeat definition and reference lookups after
   editing. Added imports and the `Price` declaration can move `total` down the
   file, so use its current definition position for the references request.
5. **Run the project tests.** Use Bash to run
   `python3 -m unittest -v test_invoice.py` and return its actual output to the
   model, so its final explanation can report what happened.

These steps describe the work, not a sequence to hardcode in a handler. A live
model chooses its own tool calls and may read `pricing.py` directly. Your job is
to make those calls work through the existing agent loop. You may already have
everything needed if the earlier stages are complete.

Follow-up LSP requests and project tests check different things. Navigation shows
whether the server can answer questions about the edited code. The tests check
the new return contract and the behavior of the callers and unrelated preview
function. Accurate locations alone don't prove the migration is correct.

### Run your completed integration

Run `codecrafters test` to exercise your agent on this task. This course test
checks the tool integration; the Python test command above checks the invoice
program through your agent's Bash tool. If the course test fails, check:

- **Loop capacity.** The scripted task uses 11 tool calls. The base loop stage
  sets no iteration cap. Any limit you added must allow this longer conversation
  and retain matching tool results. Ending the loop early can leave the model
  partway through the migration.
- **Document versions.** Track versions per URI across edits. Earlier stages already
  test successive versions 2, 3. This task edits several documents, each with its
  own version history.
- **Open-file edits.** The references query opens `pricing.py`, so its Write
  needs `didChange`, even though the earlier definition lookup only returned its
  location. Returning a location and sending `didOpen` are separate actions.
- **Closed-file edits.** Read and returned references don't open `reports.py`.
  After a successful Write, reuse `didOpen` with its new contents and version 1.
  An indexed server copy can otherwise stay stale during follow-up lookups, even
  if the edited program's tests pass on disk.

### Tests

The tester supplies the invoice project with `test_invoice.py` and runs:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with a cents field. Use LSP goToDefinition on checkout.py at line 5, character 12 and findReferences on pricing.py at line 1, character 5. Read the implementation and affected callers. Update checkout.py and reports.py so they still return integer cents. Don't modify test_invoice.py. Leave preview.total and other unrelated files unchanged. After editing, repeat definition lookup on checkout.py and findReferences at pricing.total's current definition to check the current code. Run python3 -m unittest -v test_invoice.py and report the result."
```

The supplied `test_invoice.py` contains five tests. Before migration, the three
existing behavior tests pass, while two tests for the new pricing API fail. Those
failures describe the change the agent needs to make. Leave the test file
unchanged and update the implementation and callers until all five pass.

The Bash tool result must contain the real test output. After a successful
migration, its summary looks like this, with elapsed time varying:

```text
Ran 5 tests in 0.000s

OK
```

Other cases move the definition with formatting and omit diagnostic publications.
The tester checks navigation, synchronization, the `Price` contract, both callers,
and unchanged unrelated files. Moving the definition checks that follow-up
requests use the current code rather than the starting coordinates. You don't
need to consume server diagnostics for this task; navigation, synchronized edits,
and the Bash test output provide the required feedback. The final explanation
can vary.
