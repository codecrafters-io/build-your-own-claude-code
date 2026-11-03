# Language Server Protocol - extension design

**Status:** Five implementation stages followed by a capstone.
The setup split uses dz5 and iy3 from the slugs supplied on 3 November 2026;
the four later stages keep their existing IDs. Publication is deferred.
No production release is authorized.

**Promise:** Give your existing agent precise code navigation and current analysis
so it can change an API and update its callers across files from a single prompt.

**Prerequisites:** The base agent loop, Read, Write, and Bash. Skills is not needed.
The learner builds an agent integration, not a language analyzer or editor.

## Introduce the supplied client before coding

The Configure Extensions description gives a short LSP overview. Stage one
explains why symbol navigation helps, using checkout's invoice_total alias and
the pricing implementation in the test-supplied Python project. Learners connect
the supplied client and read its extension-to-language mapping before their first
model request. The existing Read tool inspects the project. No LSP advertisement
or navigation handler is required yet.

Stage two advertises the LSP schema, adds system-prompt guidance, and installs a
temporary handler. Its test checks advertisement while still requesting only
Read. Navigation can remain unimplemented. The setup split separates a working
client call from the model-facing tool interface without introducing a temporary
command-line flag.

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
guide. Every LSP test supplies a connection.

## Finish with a coordinated change

Stage six is a capstone using the preceding five stages and the base tools.
It introduces no new LSP operation, notification handling, or Write result format.
The agent changes pricing.total from integer cents to a Price TypedDict with a
cents field, then updates checkout and both reporting calls to extract that field.
Checkout must still return 500, reporting 600, and preview must stay unchanged.

```text
Find:   Follow invoice_total to pricing.total; read the implementation.
Locate: Find references; read checkout and reporting.
Edit:   Change pricing's return value and update the affected callers.
Check:  Keep later lookups current; run the project tests through Bash.
```

The payoff is watching the existing agent loop complete a change across files.
No new code may be needed. The scripted sequence makes 11 tool calls; the base
loop stage specifies no iteration cap. Stage five already exercises versions 2
and 3 of one document; the capstone combines per-URI versions with several files.
Read each file before its own first edit; reads and writes may alternate across
files. Follow-up references target pricing.total's current definition rather
than a fixed line. A separate scripted case moves that definition with a comment.
Its references query opens pricing.py, so that Write requires didChange.
Reports.py is indexed but closed: after Write, reuse didOpen with the new text.
Read and returned reference locations do not open documents. A real server may
otherwise answer later references queries from its stale index.

Do not hardcode the migration in a learner tool handler. The offline model emits
a deterministic tool sequence to verify the integration; a live model chooses
its own sequence. Neither run requires an intentionally broken first edit.

Search is a brief motivation, not an implementation stage. Searching for total
finds unrelated preview code and imports, while the alias invoice_total needs
interpretation. Do not claim grep cannot solve it. References supply resolved
locations; the completed migration shows why those locations are useful.

## Six stages

| # | ID | Stage | New implementation | Visible evidence |
| --- | --- | --- | --- | --- |
| 1 | dz5 | Connect the LSP client | Connect the supplied client and save configuration | Configuration requested before the model; existing Read still works |
| 2 | iy3 | Advertise the LSP tool | Register the schema, prompt guidance, and temporary handler | LSP advertised in model requests; navigation not required |
| 3 | gz6 | Find the implementation | didOpen; definition routing and tool results | Follow invoice_total to pricing.total and read the implementation |
| 4 | rb6 | Find the affected callers | References with includeDeclaration true | Return pricing callers across files, excluding preview.total |
| 5 | bn2 | Keep the analysis current | Per-URI versions and synchronized successful writes | The edited import changes the definition target without a restart |
| 6 | ql9 | Change an API across files | Combine stages 1-5 with Read, Write, Bash and the agent loop | Migrate pricing and callers, preserve unrelated code, pass project tests |

Keep each setup stage focused on its own tested behavior and retain the
motivation beside the instructions it explains. The setup stages have no LSP
document payloads. Definition lookup introduces opening and querying together;
synchronization remains its own stage before the capstone combines several edits.

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
All six stages use backend-generated IDs; ql9 now grades the migration capstone instead of asynchronous diagnostics.
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

Deferred: asynchronous diagnostic feedback, completion, incremental synchronization,
workspace indexing by the client, cancellation, arbitrary shell-edit watching and
plugin discovery. The helper's notification API remains available for optional
advanced work; learners do not need to consume it in this extension.

## Verification and release gates

The tester runs the actual agent HTTP/tool loop and a real stdio child, with
protocol, tool-result and final-behavior assertions. Each stage prints evidence
of its useful outcome. Capstone checks cover navigation and reads, synchronized
edits, the Price result, both callers, unchanged unrelated files, and Bash's test
output reaching the model. A case without diagnostic publications verifies that
no diagnostic handling is required. Separate helper tests cover startup/framing
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
