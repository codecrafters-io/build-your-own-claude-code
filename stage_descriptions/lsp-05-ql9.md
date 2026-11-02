In this stage, your agent will use everything you've built to change an API
across several files from a single prompt.

### One change, several callers

The invoice project returns integer cents from `pricing.total`.
`checkout.py` imports it as `invoice_total`; `reports.py` calls it twice as `total`.
Preview has an unrelated function with the same name.

Give your agent this task:

```text
Change pricing.total to return a Price TypedDict with a cents field.
Use LSP to find the implementation and its callers. Update checkout.py and
reports.py so they still return integer cents. Leave preview.total unchanged.
Don't modify test_invoice.py. Run python3 -m unittest -v test_invoice.py.
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

### Run your completed integration

Run `codecrafters test` with your existing integration. You may pass without
new code: this capstone adds no LSP operation. If it fails, check:

- **Loop capacity.** The scripted task uses 11 tool calls. The base loop stage
  sets no iteration cap; any limit you added must allow this longer conversation
  and retain matching tool results.
- **Document versions.** Track versions per URI across edits. Stage 4 already
  tests successive versions 2, 3; this task edits several documents.
- **Open-file edits.** The references query opens `pricing.py`, so its Write
  needs `didChange`, even though definition lookup only returned its location.
- **Closed-file edits.** Read and returned references don't open `reports.py`.
  After a successful Write, reuse `didOpen` with its new contents and version 1.
  An indexed server copy can otherwise stay stale during follow-up lookups.

Your agent will typically navigate, Read the affected files, Write the migration,
repeat lookups, and run Bash. A live model chooses its own calls; it may Read
`pricing.py` directly. References can identify checkout's import rather than its
aliased call, so the model reads returned locations to find callers. Don't
hardcode the migration in a handler.

### Tests

The tester exercises navigation, reads, edits, follow-up lookups, and the Bash
test run through your agent loop. It checks the new pricing result, both callers'
integer results, synchronization, and unchanged unrelated files.
The supplied tests check the new `Price` contract as well as caller behavior;
the API tests fail until migration is complete.
Diagnostic publications are not required to complete this stage.
