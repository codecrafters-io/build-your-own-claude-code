# Your agent catches its own mistake

This small Python project is input to your agent. You can implement the agent in
any course language.

An invoice for two items at 250 cents should total **500 cents**. Currently,
`python3 checkout.py` prints `250250`: checkout passes a string to a function
that expects an integer. A language server can catch that argument error.

## Explore with the agent

The companion tester supplies a server and `.lsp.json`. Run the seven stages
against its reference agent with `make test_lsp_offline` in claude-code-tester.
For independent checks, use the pinned Pyright setup in that tester's README.

1. Use hover on pricing.py at line 1, character 5 to inspect total's signature.
2. Use goToDefinition on checkout.py at line 5, character 12 to follow the
   invoice_total alias to pricing.total.
3. Use findReferences on pricing.total and inspect the server's returned
   locations. preview.total is unrelated. Servers can treat local aliases
   differently, so preserve their results instead of guessing by spelling.
4. Use Write to change string "250" to integer 250. Diagnostic feedback should
   clear, and checkout should print 500.

These tool positions start at one and refer to the original files. Protocol
positions start at zero. After an edit, use the current text's positions.

A demonstration prompt for the completed agent:

> The invoice for two 250-cent items prints 250250. Use the language server to
> inspect the function and follow its imported alias. Fix the argument using
> Write and inspect the diagnostic feedback. Confirm that the error cleared,
> show what changed, and run the project tests.

The supplied invoice is already broken, so this task has a useful outcome
without deliberately breaking it again. It demonstrates navigation, a repair and
diagnostic clearing.

## See the agent recover from a bad edit

The final graded stage is a controlled regression test. It starts with valid
code and introduces the same argument error deliberately, so every learner can
see the agent recover even when a model would otherwise make the correct edit
first. The tester's model selects a repair only after receiving the type error.

The tester shows the verified feedback after both writes:

```text
Edit feedback for checkout.py: Argument of type str cannot be assigned to parameter price of type int
Repair feedback for checkout.py: diagnostics []
```

If this stalls, check that Write sends the new contents to the server, the
reader handles notifications while waiting for replies, and each write waits for
a new publication for its own file. An empty list clears an error only when the
server actually publishes it.

## Check the project

```bash
python3 -m unittest -v test_invoice.py
```

The checkout test intentionally fails in the supplied project. After repairing
its argument, all three tests pass. The other tests protect reports.py and the
unrelated preview.py behavior.
