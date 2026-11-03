In this stage, you'll use your agent to change an API across several files from a single prompt.

### One change, several callers

The invoice project returns integer cents from `pricing.total`.
`checkout.py` imports it as `invoice_total`. `reports.py` calls it twice as `total`.
Preview has an unrelated function with the same name.

Give your agent this task:

```text
Change pricing.total to return a Price TypedDict with a cents field.
Use LSP to find the implementation and its callers. Update checkout.py and
reports.py so they still return integer cents. Leave preview.total unchanged.
Don't modify test_invoice.py. Run python3 -m unittest -v test_invoice.py.
```

A `TypedDict` describes a dictionary with named, typed fields. The new API is:

```python
from typing import TypedDict


class Price(TypedDict):
    cents: int


def total(price: int, quantity: int) -> Price:
    return {"cents": price * quantity}
```

Each affected call must now read the `cents` field. Checkout should still return
`500`, and reporting should still return `600` after adding both amounts.

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


### Run your completed integration

Run `codecrafters test`. If it fails, check:

- **Loop capacity.** The scripted task uses 11 tool calls. The base loop stage
  sets no iteration cap. Any limit you added must allow this longer conversation
  and retain matching tool results.
- **Document versions.** Track versions per URI across edits. Earlier stages already
  test successive versions 2, 3. This task edits several documents.
- **Open-file edits.** The references query opens `pricing.py`, so its Write
  needs `didChange`, even though definition lookup only returned its location.
- **Closed-file edits.** Read and returned references don't open `reports.py`.
  After a successful Write, reuse `didOpen` with its new contents and version 1.
  An indexed server copy can otherwise stay stale during follow-up lookups.

Your agent navigates and reads each file before its first edit. It may alternate
Read and Write across files, repeat lookups, and run Bash. A live model chooses
its own calls. It may Read
`pricing.py` directly. References can identify checkout's import rather than its
aliased call, so the model reads returned locations to find callers. Don't
hardcode the migration in a handler.

### Tests

The tester supplies the invoice project with `test_invoice.py` and runs:

```bash
$ ./your_program.sh -p "Change pricing.total to return a Price TypedDict with a cents field. Use LSP goToDefinition on checkout.py at line 5, character 12 and findReferences on pricing.py at line 1, character 5. Read the implementation and affected callers. Update checkout.py and reports.py so they still return integer cents. Don't modify test_invoice.py. Leave preview.total and other unrelated files unchanged. After editing, repeat definition lookup on checkout.py and findReferences at pricing.total's current definition to check the current code. Run python3 -m unittest -v test_invoice.py and report the result."
```

The Bash result must return the passing test output. Its summary looks like this,
with elapsed time varying:

```text
Ran 5 tests in 0.000s

OK
```


Other cases move the definition with formatting and omit diagnostic publications.
The tester checks navigation, synchronization, the `Price` contract, both callers,
and unchanged unrelated files. The API tests fail until migration is complete.
The final explanation can vary.
