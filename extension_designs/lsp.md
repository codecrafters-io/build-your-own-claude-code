# Language Server Protocol - extension design

**Status:** Six implementation stages, ending with diagnostic feedback during an API migration.
The setup split uses dz5 and iy3 from the slugs supplied on 3 November 2026;
the four later stages keep their existing IDs. Publication is deferred.
No production release is authorized.

**Promise:** Give your existing agent precise code navigation and current analysis
so it can change an API, use diagnostic feedback to repair its callers, and verify the result.

**Prerequisites:** The base agent loop, Read, Write, and Bash. Skills is not needed.
The learner builds an agent integration, not a language analyzer or editor.

## Introduce the supplied client before coding

The Configure Extensions description gives a short LSP overview. Stage one
explains why symbol navigation helps, using checkout's invoice_total alias and
the pricing implementation in the test-supplied Python project. Learners connect
the supplied client, whose initialization fetches its extension-to-language
mapping before their first model request. The existing Read tool inspects the
project. No LSP advertisement or navigation handler is required yet.
Current starters include the client. Each language's setup section links directly
to the current client file and gives its destination path if a download is needed.
The lesson introduces the language mapping in Stage 3, alongside the `didOpen`
field that uses it.

Stage two advertises the LSP schema, adds system-prompt guidance, and installs a
temporary handler. Its test requests a definition lookup and checks that the
placeholder response reaches the matching model tool call. Navigation can remain
unimplemented; an agent with working navigation can also pass. The setup split
separates client initialization from the model-facing tool interface without
introducing a temporary command-line flag.

Stage three follows invoice_total to pricing.total. It reuses the connection and
schema, adding document opening, definition routing, and matching tool results.
Its exercise makes one successful lookup followed by Read; multiple definitions,
missing definitions, and server-error tool results are outside this stage.
Stage four locates callers in checkout and reporting, excluding preview.total.
Stage five changes checkout's import to discounts and synchronizes successful
writes so definition lookup follows the new target. It covers repeated versions
and writes before opening a file; failure recovery is outside this stage.
The same invoice project continues through all six stages, independent of the
agent's implementation language.

Learners see the supplied LSP client as their interface. Server startup and
message delivery are provided; helper transport internals stay in the optional
guide. Every LSP test supplies a connection. Supplied environment factories return
no client when that connection is unconfigured, allowing base-course and local
runs to continue without advertising LSP. Configured initialization failures
remain errors.

## Finish with diagnostic feedback and repair

Stage six adds consumption of asynchronous diagnostic notifications. Stage five
only sends document updates; an otherwise complete Stage 5 agent must fail Stage
6 if it does not return diagnostic feedback to the model.

Keep the API migration: pricing.total changes from integer cents to a Price
TypedDict with a cents field. Checkout and both reporting calls extract that
field, preserving checkout's 500 cents and reporting's 600 cents. Preview stays
unchanged. A scripted intermediate checkout edit returns Price from an int
function, producing a type error. The next Write repairs that return and must
surface a new, empty diagnostic report. Normal model runs need not deliberately
introduce an error.

After every successful Write to a supported file, preserve the write result and
attach the written file's current publishDiagnostics params under diagnostics.
Drain pending notifications before saving, synchronize with Stage 5's version
map, then poll with an overall deadline. Advance the cursor for every batch.
Filter by URI and, when present, the synchronized version; accept unversioned
reports received after the pre-edit drain. Use the latest matching report in a
batch. Preserve complete messages, severities, zero-based ranges, and optional
versions. An empty diagnostic array clears earlier errors; an empty notification
batch is not a clean report. If no report arrives by the deadline, preserve the
successful save and return diagnosticsError with an explicit timeout.

The supplied helper already queues notifications. Its transport is unchanged;
learners add cursor management, report selection, and feedback in Write. No new
model-facing LSP operation is needed. The scripted integration makes 12 tool
calls. Graded variants cover normal error/repair feedback, stale and unrelated
notifications, unversioned reports, missing publications, and a moved definition.

Read each file before its own first edit. Follow-up references target the current
pricing.total definition. The pricing references request opens pricing.py, so its
Write sends didChange; reports.py is indexed but closed and its Write sends
didOpen. Navigation still verifies current positions, and actual Bash output and
independent project tests still verify the completed migration.

Do not hardcode the migration in the agent. Grading supplies deterministic tool
calls and checks the actual server reports in their matching Write results.
Separate live-model checks cover whether the model uses that feedback to choose
repairs.

Search is a brief motivation, not an implementation stage. Searching for total
finds unrelated preview code and imports, while the alias invoice_total needs
interpretation. Do not claim grep cannot solve it. References supply resolved
locations; the completed migration shows why those locations are useful.

## Six stages

| # | ID | Stage | New implementation | Visible evidence |
| --- | --- | --- | --- | --- |
| 1 | dz5 | Connect the LSP client | Initialize the supplied client, which fetches the language mapping | Mapping fetched before the first model request |
| 2 | iy3 | Advertise the LSP tool | Register the schema, prompt guidance, and temporary handler | LSP advertised; a matching tool response reaches the model; navigation not required |
| 3 | gz6 | Find the implementation | didOpen; definition routing and tool results | Follow invoice_total to pricing.total and read the implementation |
| 4 | rb6 | Find the affected callers | References with includeDeclaration true | Return pricing callers across files, excluding preview.total |
| 5 | bn2 | Keep the analysis current | Per-URI versions and synchronized successful writes | The edited import changes the definition target without a restart |
| 6 | ql9 | Repair edits with diagnostics | Collect current diagnostic reports after Write and return feedback to the model | Surface a caller error, confirm its repair clears it, and pass project tests |

Keep each setup stage focused on its own tested behavior and retain the
motivation beside the instructions it explains. The setup stages have no LSP
document payloads. Definition lookup introduces opening and querying together;
synchronization remains its own stage before diagnostic feedback adds a repair loop.

## Supply the connection

[The helper](../extension_helpers/advanced_usage.md) owns server startup, framing,
initialization, response IDs, notification queuing, and process cleanup. Native
starter clients for all ten course languages connect to its supplied URL. The
course starts it automatically; no manual server installation is required for
graded tests. Its local HTTP interface is course scaffolding, not LSP.

The learner constructs didOpen, definition, references and didChange messages,
tracks document versions, and supplies model tool results. Neither the helper
nor the server runs the agent or chooses edits. Read, Write, and Bash remain
existing base-course tools; LSP navigation joins their existing dispatch.

The standalone helper supports an independently installed server through the
same .lsp.json command/args/extensionToLanguage shape. Transport internals and
manual installation are optional material. No plugin manager is required.

## Scope and fidelity

Navigation is a documented product capability:
[Claude Code's TypeScript plugin](https://claude.com/marketplace/plugins/typescript-lsp).
Document opening, changes, definition requests and references follow
[Microsoft's LSP overview](https://github.com/microsoft/language-server-protocol/blob/gh-pages/_overviews/lsp/overview.md).
The prior independent product check used Claude Code 2.1.266. Retain a separate
native-product smoke check.

Hover, standalone initialization and response-reading stages are removed. Their
IDs ls1, ir2, hv2 and the combined setup ID cx7 are retired, not repurposed.
All six stages use backend-generated IDs; ql9 grades diagnostic feedback during the API migration.
Rename remains outside the built-in LSP tool's course scope.

The fixture recognizes the documented invoice project; it is not a Python
analyzer. Pyright independently verifies navigation and the actual Price migration.
Its pricing references identify checkout's import, rather than the aliased call;
the model reads the returned file to inspect its uses. Preserve server results.
LSP supplies a persistent analysis connection and structured navigation. Project
tests check behavior, while separate grader assertions check the new pricing API
and unchanged unrelated files.
The supplied test_invoice.py also tests the Price shape and type contract;
those two tests intentionally fail before migration. Prompts protect that file.

Deferred: completion, incremental synchronization, workspace indexing by the client,
cancellation, arbitrary shell-edit watching, and plugin discovery. Diagnostic
feedback in this extension covers successful writes to supported Python files.

## Run the LSP checks locally

In the companion `claude-code-tester` checkout, with Go 1.25.5 and Python 3.10+:

```sh
make test_lsp
make test_lsp_offline
make test_lsp_with_pyright
```

The first two need no model credentials. The third requires an installed
Pyright language server and checks the integration independently of the fixture.
For live-model trials, set `CODECRAFTERS_SECRET_OPENROUTER_API_KEY` and run
`make test_lsp_with_users_code`. Learner trials and live-model reliability checks
remain release gates.

## Verification and release gates

The tester runs the actual agent HTTP/tool loop and a real stdio child, with
protocol, tool-result and final-behavior assertions. Each stage prints evidence
of its useful outcome. Stage 6 checks cover navigation and reads, synchronized
edits, diagnostic error/repair feedback, bounded diagnostic timeouts, the Price
result, both callers, unchanged unrelated files, and actual Bash output. A
progression regression proves that Stage 5 passes without diagnostic feedback
and Stage 6 rejects that same agent. Separate helper tests cover startup/framing
so those checks do not inflate graded stages.

Regenerate recorded output when cases or prompts change. Verify the reference
agent against Pyright and inspect the migration through the CLI. Check starter
helper parity and course/tester stage registration together.

The revised design still needs a learner pacing trial and repeated live-model
runs with valid CODECRAFTERS_SECRET_OPENROUTER_API_KEY before publication.
Deterministic scripted runs establish integration, not live-model reliability.
Stage IDs are allocated. Deploy matching course content and a tester release
with these IDs together.

See the [local verification record](../extension_helpers/verification.md) for
passed checks and remaining release checks.
