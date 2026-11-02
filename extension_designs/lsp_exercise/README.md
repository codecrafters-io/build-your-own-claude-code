# Change an API and watch the agent repair a missed caller

The invoice currently returns integer cents: checkout is 500 and reporting is 600. Preview has an unrelated total function. The task is to change pricing.total
to return a Price object containing cents, then update its callers.

A partial migration returns the whole Price object from checkout_total, which
still promises int. The file saves successfully; language analysis reports the
return-type error. After the agent changes it to return amount["cents"], the
error clears and the original behavior is preserved.

## Four visible milestones

1. Follow checkout's invoice_total alias to pricing.total.
2. Find pricing's callers in checkout and reporting, excluding preview.total.
3. Temporarily change checkout's import from pricing to discounts and watch
   definition lookup follow the new target. Restore pricing before migration.
4. Replay the incomplete API migration and let Write feedback drive its repair.

Text search remains useful. A search for total also finds unrelated code, and
its aliased calls require interpretation. The language server supplies resolved
locations and type feedback; it does not replace behavioral tests.

## Run the controlled before/after demonstration

In the companion tester checkout:

```sh
make test_lsp_offline
```

The final stage runs a fixed first attempt through the real reference-agent loop.
Its model requests the repair only after the Write result contains an error.
The output shows:

```text
Partial API migration: Write saved checkout.py, but the caller still returns Price as int
Edit feedback for checkout.py: Type Price is not assignable to return type int
Repair feedback for checkout.py: diagnostics []
```

This is a controlled demonstration, not a claim that a live model must make a
mistake. The tester checks final file contents and the matching tool results.
For an independent language analyzer, run `make test_lsp_with_pyright`.

## Try your completed agent

The course supplies the server automatically during grading. For an optional
local run with your own server, use the [helper guide](../../extension_helpers/README.md).
This directory already contains .lsp.json and pyrightconfig.json.

Try this ordinary prompt:

> Change pricing.total to return a Price TypedDict with a cents field. Find its
> implementation and callers with LSP. Update checkout and reporting while
> preserving their integer results. Use Write's diagnostic feedback to repair
> any type errors, leave preview.total unchanged, and run the project tests.

The model may make the right edit on its first attempt; recovery isn't guaranteed
to occur in a live run. LSP diagnostic clearing establishes the reported errors
are gone, while the tests below check behavior.

```sh
python3 -m unittest -v test_invoice.py
```

All three tests pass initially and should still pass after the complete migration.
Python is the analyzed language; your agent can use any course language.
