In this stage, your agent will use everything you've built to change an API
across several files from a single prompt.

### One change, several callers

The invoice project currently returns integer cents from `pricing.total`.
Checkout imports it as `invoice_total`; reporting calls it twice as `total`.
Preview has an unrelated function with the same name.

Give your agent this task:

```text
Change pricing.total to return a Price TypedDict with a cents field.
Use LSP to find the implementation and its callers. Update checkout and
reporting so they still return integer cents. Leave preview.total unchanged
and run python3 -m unittest -v test_invoice.py to check the result.
```

The new pricing API should look like this:

```python
from typing import TypedDict


class Price(TypedDict):
    cents: int


def total(price: int, quantity: int) -> Price:
    return {"cents": price * quantity}
```

Each affected call must now read the `cents` field. Checkout should still return
`500`, and reporting should still return `600` after adding both amounts.

### Bring the previous stages together

Reuse your existing connection, LSP handler, and agent loop:

1. **Find the implementation.** Follow checkout's `invoice_total` alias with
   `goToDefinition`, then Read the returned file.
2. **Find the callers.** Use `findReferences` on `pricing.total`, then Read the
   affected files. The results identify checkout and reporting, excluding preview.
3. **Make the edits.** Let the model use Write to update pricing and both callers.
   Keep sending didChange for open documents, as in the previous stage, so later
   lookups see the edited code.
4. **Check the result.** Return Bash's test output to the model so it can confirm
   that the original behavior is preserved.

This is a capstone: it adds no new LSP operation or diagnostic handling. Your
agent's tools should work together without hardcoding the migration in a handler.

### Tests

The tester exercises navigation, reads, edits, follow-up lookups, and the Bash
test run through your agent loop. It checks the new pricing result, both callers'
integer results, synchronization, and that unrelated files remain unchanged.
Diagnostic publications are not required to complete this stage.
