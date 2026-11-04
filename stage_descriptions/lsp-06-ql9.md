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

The tester supplies the Python invoice project and gives your agent this task:

```text
Change pricing.total to return a Price TypedDict with a cents field.
Use LSP goToDefinition on checkout.py at line 5, character 12 and findReferences
on pricing.py at line 1, character 5. Read the implementation and affected
callers. Update checkout.py and reports.py so they still return integer cents.
Don't modify test_invoice.py. Leave preview.total and other unrelated files
unchanged. After editing, repeat definition lookup on checkout.py and
findReferences at pricing.total's current definition to check the current code.
Run python3 -m unittest -v test_invoice.py and report the result.
```

The project is Python regardless of your agent's implementation language.
The Python below describes the code your agent will edit.

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
amounts. The callers' integer results remain the same:

| Call | Result after the change |
| --- | --- |
| `pricing.total(37, 4)` | `{"cents": 148}` |
| `checkout_total()` | `500` |
| `report_total()` | `600` |

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

Let the model choose its tool calls and execute them through your existing agent
loop. It may read `pricing.py` directly or alternate reads and writes across
files. You may already have everything needed if the earlier stages are complete.

Follow-up LSP requests and project tests check different things. Navigation shows
whether the server can answer questions about the edited code. The tests check
the new return contract and the behavior of the callers and unrelated preview
function. Accurate locations alone don't prove the migration is correct.

### Run your completed integration

Run `codecrafters test` to exercise your agent on this task. This course test
checks the tool integration; the Python test command above checks the invoice
program through your agent's Bash tool. If the course test fails, check:

- **Loop continuation.** Allow the conversation to continue through navigation,
  reads, writes, and test execution, retaining matching tool results throughout.
- **Document versions.** Use Stage 5's shared URI-to-version map for navigation
  and Write. Each document keeps its own version history across edits.
- **Open-file edits.** A references query on `pricing.py` opens it. A following
  Write sends `didChange` with the next version.
- **Closed-file edits.** Read and returned references don't open `reports.py`.
  If it is still closed when written, send `didOpen` with its new contents and
  version 1 so follow-up lookups use the updated code.

### Tests

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

The tester checks that the `Price` contract and both callers pass all five
project tests, while `test_invoice.py` and unrelated files remain unchanged.
Follow-up navigation must use the edited code and the function's current
position, including when formatting moves its definition. The actual Bash
output must reach the model through your tool-result flow.

Your agent can now follow symbols, inspect their uses, make coordinated edits
across files, and verify the result with project tests.
