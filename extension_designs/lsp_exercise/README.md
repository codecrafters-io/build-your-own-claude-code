# Change an API across files

The invoice currently returns integer cents: checkout is 500 and reporting is 600.
Preview has an unrelated total function. The task is to change pricing.total to
return a Price TypedDict containing cents, then update both callers while
preserving their integer results.

## Six visible milestones

1. Connect the supplied LSP client, read configuration, and inspect this project
   with the agent's existing Read tool.
2. Advertise the LSP tool and add a temporary handler before implementing navigation.
3. Follow checkout's invoice_total alias to pricing.total.
4. Find pricing's callers in checkout and reporting, excluding preview.total.
5. Temporarily change checkout's import from pricing to discounts and watch
   definition lookup follow the new target. Restore pricing before migration.
6. Return current diagnostics after Write, repair type errors during the API
   migration, confirm they clear, and run the project tests.

Text search remains useful. A search for total also finds unrelated code, and
its aliased calls require interpretation. The language server supplies resolved
locations; behavioral tests check the completed change.

## Run the capstone demonstration

In the companion tester checkout:

```sh
make test_lsp_with_users_code
```

Set `CODECRAFTERS_SECRET_OPENROUTER_API_KEY` before running this command. The
reference agent requests responses from OpenRouter, and the model chooses its
navigation, read, write, and Bash calls. The tester checks diagnostic feedback in
matching Write results, synchronized document contents, the changed API, and
preserved caller behavior. It also checks that unrelated files stay unchanged.
When a server publishes no diagnostics, Write must report a feedback timeout
while preserving the successful save.

For offline protocol and checker tests, run `make test_lsp`. For an independent
language analyzer, run `make test_lsp_with_pyright`.

## Try your completed agent

The course supplies the server automatically during grading. For an optional
local run with your own server, use the [local-server guide](../../extension_helpers/advanced_usage.md#run-with-your-own-server).
This directory already contains .lsp.json and pyrightconfig.json.

Try this prompt:

> Change pricing.total to return a Price TypedDict with a cents field. Use LSP
> to find the implementation and its callers. Inspect diagnostic feedback from
> Write and repair reported type errors. Update checkout.py and reports.py
> so they still return integer cents. Leave preview.total unchanged. Don't modify
> test_invoice.py. Run python3 -m unittest -v test_invoice.py.

The final stage adds diagnostic feedback to Write, using the helper's queued
notifications. The model determines the number of tool calls; the base loop
stage sets no iteration cap. A Stage 5 agent without feedback collection fails
Stage 6.
Keep document versions per URI, send didChange for open-file writes, and reuse
didOpen after successful writes to supported closed files. In this sequence,
references opens pricing.py but only returns locations in reports.py; Read
doesn't open it. An indexed copy can otherwise stay stale after Write.

The model decides which calls and edits to make. Pyright returns checkout's
import location rather than the aliased call; Read lets the model inspect the
affected file. The independent Pyright check deliberately shifts reports.py's
lines and verifies exact follow-up reference positions, rather than filenames.

```sh
python3 -m unittest -v test_invoice.py
```

The three existing behavior tests pass initially. Two API tests fail until
pricing returns a Price TypedDict with integer cents. All five tests should
pass after the complete migration; leave the tests unchanged.
Python is the analyzed language; your agent can use any course language.
