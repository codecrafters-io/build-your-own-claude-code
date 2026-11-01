# Fix the invoice, then rename its calculation

This is the sample project for the LSP extension. It is deliberately small
enough to read in a minute. The Python project is input to the learner's agent;
the agent can be implemented in any course language.

## The bug

An invoice for two items at 250 cents should total **500 cents**. Instead:

```bash
python3 checkout.py
```

prints `250250`.

`pricing.total` expects an integer price, but checkout passes a string. Python
repeats the string instead of multiplying two integers. A language server with
type checking can point to the invalid argument before running the program.

## Explore with the agent

The companion tester supplies `.lsp.json` and its controlled language server
during stage runs. To run all eight stages against its reference agent, use
`make test_lsp_offline` in the `claude-code-tester` checkout. To explore this
project with your own completed agent, supply a language server using the
configuration described in [the extension design](../lsp.md), then work through
these tasks:

1. Use hover on `pricing.py`, line `0`, character `4`, to inspect the signature
   of `total`.
2. Go to the definition of `invoice_total` in `checkout.py`, line `4`, character
   `11`. It should resolve to `pricing.total`.
3. Find references to `pricing.total`. Compare the result to a text search for
   `total`: aliases belong to the symbol, but `preview.total` does not.
4. Change the string argument `"250"` to the integer `250` using Write. The
   current diagnostics should clear, and checkout should print `500`.
5. Rename `pricing.total` to `total_cents` using the LSP rename operation.

All positions above are zero-based. These instructions refer to the original
files; after edits, use the current positions.

The finished project should have:

- A definition named `total_cents` in `pricing.py`
- `from pricing import total_cents as invoice_total` in `checkout.py`, with the
  local call still named `invoice_total`
- An updated import and both calls in `reports.py`
- Exactly the original contents of `preview.py`, including its comment and
  string

The two calls on one line in `reports.py` make edit order matter. Applying the
first rename before the second shifts the second range.

## Try the full task

An optional demonstration prompt for the completed agent:

> The invoice for two 250-cent items prints 250250. Use the language server to
> inspect the function and follow its imported alias. Fix the argument and check
> the diagnostics. Then rename pricing.total to total_cents using LSP,
> preserving the local invoice_total alias and the unrelated total in
> preview.py. Run the project tests.

This combines existing operations. The graded final stage uses a narrower rename
prompt so a diagnostic or model-planning failure doesn't hide a bug in applying
edits.

## Check the project

From this directory, run:

```bash
python3 -m unittest -v test_invoice.py
```

The checkout test intentionally fails in the supplied project. After the repair
and rename, all three tests should pass. They check behavior; the course tester
must additionally inspect exact file contents and LSP messages to prove that the
operations were implemented.

The supplied course server and reference agent are implemented in the companion
`claude-code-tester` repository. Running this Python project and its tests needs
no server. The exercise server uses a controlled project shape and is not a
general Python analyzer.
