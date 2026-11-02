# Language Server Protocol - extension design

**Status:** Seven graded stages within Claude Code's built-in LSP capabilities.
Stage-ID allocation is deferred at the user's request. Existing IDs remain
pending allocation confirmation. No production publication is authorized.

**Description:** In this challenge extension, you'll connect your Claude Code
implementation to a language server using the Language Server Protocol. Along
the way, you'll learn about JSON-RPC, code navigation, document synchronization,
and diagnostic feedback after edits.

**Axis:** The capabilities of a language-server connection inside the agent.

**Prerequisites:** The base agent loop, Read, Write, and Bash. Skills is not a
prerequisite. The learner implements a client, not a Python analyzer.

## Stage design

| #   | Current ID | Stage                             | Difficulty | New implementation                                            | Observable assertions                                                                                                                                  |
| --- | ---------- | --------------------------------- | ---------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `ls1`      | Send the initialization request   | easy       | Start the configured server and frame one JSON-RPC request    | Correct command, arguments, cwd and initialize fields; valid UTF-8 byte framing; cleanup and no-config behavior                                        |
| 2   | `ir2`      | Read the initialization response  | medium     | Buffer frames, match IDs and send initialized                 | Partial/coalesced frames survive; notifications do not become responses; startup failure is reported                                                   |
| 3   | `hv2`      | Look up a symbol's type           | medium     | Advertise LSP hover, open documents and forward results       | Editor coordinates become protocol coordinates; the server-only token reaches the model; null/error and repeated queries work                          |
| 4   | `df3`      | Go to a definition                | easy       | Route goToDefinition and return locations                     | Aliases resolve; every returned location reaches the model; a missing result is preserved                                                              |
| 5   | `rf4`      | Find a symbol's references        | easy       | Route findReferences with includeDeclaration true             | The declaration is requested; all returned locations survive; unrelated names and empty results are handled                                            |
| 6   | `sy5`      | Keep the server up to date        | medium     | Synchronize successful writes and increment document versions | Subsequent hover sees edits; successive writes use one process; failed writes send no changes                                                          |
| 7   | `dg6`      | Feed diagnostics back after edits | medium     | Consume push diagnostics and return feedback after Write      | A bad edit yields an error and repair clears it; unversioned reports work; stale versioned reports and missing feedback cannot appear as fresh success |

Each stage has two to four cases. Read and Write remain base-course tools.
Definition and references are short applications of the established transport,
with new routing and result behavior. The last stage completes the useful
edit-feedback-repair loop rather than adding a harder feature for its own sake.
There is no requirement to end on a hard stage.

The second stage no longer requires implementing graceful shutdown, document
closing, or an ordering constraint against the first model request. Closing
stdin and waiting for the process, introduced in the opener, remains sufficient
for the supplied server. A complete client can use shutdown/exit. Its new work
is response reading and the initialization handshake. A learner timing trial is
still needed before claiming that this pacing has been validated.

## Research and product fidelity

Sources checked for this revision:

- [Claude Code documentation index](https://code.claude.com/docs/llms.txt):
  identifies plugins, code intelligence, tool behavior and configuration as the
  relevant documentation families. Authentication, billing, deployment,
  collaboration and UI customization are outside this extension.
- [Code intelligence](https://code.claude.com/docs/en/plugins/code-intelligence):
  symbol navigation and diagnostic feedback after edits are the product payoff.
- [LSP plugin components](https://code.claude.com/docs/en/plugins/components#lsp-servers):
  `.lsp.json` maps server names to command/args and extensionToLanguage entries.
- [LSP tool behavior](https://code.claude.com/docs/en/tools-reference#lsp-tool-behavior):
  the tool is read-only. Its interface is not the wire protocol.
- [LSP 3.17](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/):
  framing, initialization, document synchronization and push diagnostics.

The independent implementation check uses the exact CI-pinned Claude Code
**2.1.266**, not only current documentation or the locally installed newer CLI.
Its observed tool schema has hover, goToDefinition and findReferences, with
filePath and one-based line/character values. Wire positions are zero-based. Its
references request fixes includeDeclaration to true. It advertises
publishDiagnostics.versionSupport false and accepts unversioned diagnostics. The
course no longer teaches a rename or diagnostics operation in that tool.

## Explicit course boundaries

The course reads one server configuration from `.lsp.json` in the project root.
It uses the product's configuration shape, while deferring plugin discovery,
installation, permissions, multiple servers and file-type conflicts. The native
CLI check loads that configuration with `--plugin-dir`; learners do not need to
build a plugin manager. The opening tests explicitly exercise startup.
Navigation tests accept starting the server before the model loop or on the
first LSP call.

The supplied server is a deterministic exercise fixture for the invoice project,
not a Python language server. Pyright 1.1.414 is used separately to validate the
client against an independent server. The project sets typeCheckingMode basic
for that check; a running server alone does not ensure argument-type errors are
enabled.

The course returns structured locations and diagnostics in tool results so the
tester can compare them without grading model prose. Claude Code formats
navigation results for display and can deliver diagnostics in a separate
conversation attachment. The native check observes those product channels
separately; it is not claimed to pass the exact recorded learner-stage fixture.

For the controlled fixture, each open or change produces a publication, except
in the explicit missing-publication case. A successful Write waits for new
feedback and reports a bounded error if it does not arrive. That is an exercise
contract, not a universal language-server timing guarantee. Versioned reports
can be checked against document versions. Unversioned reports replace the list
in arrival order and cannot prove which edit was analyzed. The reference client
accepts both, rather than discarding every unversioned report.

The native CLI check keeps Bash available, as it is in the completed base
course. In 2.1.266, removing both Bash and PowerShell also suppresses automatic
LSP diagnostic attachments. The scripted model never invokes a shell command.

Deferred capabilities include completion, incremental text synchronization,
workspace indexing, cancellation, server requests and background shell-file
watching. The small client remains useful without implementing an editor.

## One exercise and a concrete payoff

The finale is "your agent catches its own mistake." Navigation gives it the
relevant definition, synchronization lets the server analyze its edit, and
diagnostic feedback lets it repair an error without the user intervening. No
build or test command is needed to reveal the type error. Go to definition
provides an earlier payoff by following a local alias to the function it names.

The sample in [lsp_exercise](lsp_exercise/README.md) calculates an invoice in
cents. pricing.py defines total; checkout.py imports it as invoice_total and
passes string "250" instead of integer 250. reports.py contains other calls,
while preview.py has an unrelated total.

The completed agent can follow the alias, inspect the type, change the argument,
and receive diagnostic feedback after its edit. Checkout then returns integer
500, and the project tests pass. The final graded case starts with a valid
checkout and deliberately introduces that argument error. Its scripted model
selects the repair only after the preceding Write result contains an error
diagnostic. The repaired Write must then carry an empty list. Each graded case
starts in a fresh workspace. The example's protocol ranges are zero-based, while
its tool prompts use editor positions starting at one. Both coordinate systems
are stated where introduced.

## Changes from the original design

- Eight graded stages became seven. The user chose to stay within the official
  built-in LSP tool's capabilities and make diagnostic-driven repair the finale.
  Rename is valid LSP but is outside that tool's operations. Its stage, optional
  exercise, tester registration, scenarios, assertions and rename-only helpers
  were removed. The old rn7 ID is retired from the active inventory, not
  reallocated.
- The project configuration now uses a named server map and extensionToLanguage.
  The original flat command/args/languageId object was a course invention.
- Tool coordinates and operation names now match the pinned product. The earlier
  include_declaration and new_name arguments are gone.
- Stage two focuses on the reader and initialized handshake. Shutdown is no
  longer a separate requirement hidden inside response reading.
- The finale accepts unversioned reports and integrates feedback into Write. The
  earlier diagnostics operation and mandatory versioned publications were course
  inventions that prevented the advertised Pyright feedback loop.
- The user explicitly deferred official slug allocation and authorized all other
  revisions on 1 November 2026. Current IDs remain provisional until that step.

## Verification and publication gates

The offline scenarios exercise the agent HTTP/tool loop and a real stdio child.
They inspect protocol traffic, tool-result boundaries and file state, rather
than matching a model's final wording. Broken clients are checked for missing
handshakes, discarded results, incorrect position conversion, unsynchronized
writes and false empty diagnostics.

Independent checks cover the revised Python client against Pyright and the
pinned Claude Code against Pyright with a local scripted model. Scripted runs
establish deterministic integration, not live-model reliability. The recorded
stage output must be regenerated whenever the case set or prompts change.

Verified locally on 1 November 2026:

- Regenerated fixtures for all 23 cases and passed `make test_offline`,
  including all eight deliberately broken clients. One reuses a cached
  unversioned diagnostic list after editing.
- Passed the reference-client Pyright check and the official Claude Code 2.1.266
  Pyright check. The native check requires the type error to reach the model
  before it selects the repair.
- Mutation-checked the scripted model's feedback gate. Empty diagnostics,
  warnings and an older tool result cannot trigger repair.
- Passed `go vet ./...`, Markdown formatting and course/tester YAML equality.
  Inspected the rendered finale in the local stage editor. The sample invoice
  fails before repair and passes all three project tests after repair.

The opening stages connect initialization and message reading to that same
invoice task. The completed-agent demonstration fixes the broken invoice
directly. The graded finale explains its deliberate bad edit as a controlled
regression test, then prints the verified error and clearing after recovery.
Failure messages point at synchronization, notification dispatch and cached
feedback. These changes address the known pacing and visibility concerns, but
enjoyment still needs a learner trial.

Before release, run the live-model scenarios repeatedly with a valid
CODECRAFTERS_SECRET_OPENROUTER_API_KEY and run the model-backed prose rules. The
earlier CI credential returned HTTP 401. No valid key is configured locally, so
live-model trials and the requested 100-run live flakiness check remain
publication blockers. Allocated stage IDs and a learner pacing trial also remain
outstanding. Staging import and tester activation are separate deployment steps;
no production merge or release is part of this revision.
