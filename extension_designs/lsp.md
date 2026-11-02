# Language Server Protocol - extension design

**Status:** An introduction followed by four implementation stages and a capstone.
Stage IDs use the first five slugs supplied from the backend generator on
2 November 2026. Publication is deferred. No production release is authorized.

**Promise:** Give your existing agent precise code navigation and current analysis
so it can change an API and update its callers across files from a single prompt.

**Prerequisites:** The base agent loop, Read, Write, and Bash. Skills is not needed.
The learner builds an agent integration, not a language analyzer or editor.

## Introduce the server and helper before coding

The Configure Extensions description is a short overview of LSP and the
capabilities learners will add. Keep setup instructions, code examples, and the
exercise details in the stages.

Stage one explains the server and shows the route from a model tool call through
the learner's handler and supplied connection to the language server, and back as
a tool result. The helper owns starting the server and delivering messages. The
learner owns document contents, queries, synchronization and model-visible results.

It also shows pricing.py and checkout.py from the test-supplied invoice project,
including the aliased import. These are files the agent analyzes in its test
working directory, not extra files the learner must build into the agent.

Stage one links to the example files, connects the supplied client, retrieves
the extension-to-language mapping, and shows the JSON schema to add directly
to the learner's existing tool list.
It uses the existing Read tool to inspect the example; it does not require an
LSP tool handler, file URIs, coordinates, or document messages. Every LSP test
supplies a connection; learners construct the client without an environment check.

Stage two focuses on following invoice_total to pricing.total. It reuses the
connection and schema, adding only document opening, definition routing, and
matching tool results. It introduces notify and request payloads when needed.

The same invoice project continues through all five stages. Stage three finds
pricing's callers in checkout and reporting, excluding the unrelated preview.total.
Stage four demonstrates stale server text by changing checkout's import to
discounts, then synchronizing the edit so definition lookup follows the new target.

## Finish with a coordinated change

Stage five is a capstone using the preceding four stages and the base tools.
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
Do not hardcode the migration in a learner tool handler. The offline model emits
a deterministic tool sequence to verify the integration; a live model chooses
its own sequence. Neither run requires an intentionally broken first edit.

Search is a brief motivation, not an implementation stage. Searching for total
finds unrelated preview code and imports, while the alias invoice_total needs
interpretation. Do not claim grep cannot solve it. References supply resolved
locations; the completed migration shows why those locations are useful.

## Five short stages

| #   | Current ID | Stage                      | New implementation                                                         | Visible evidence                                                          |
| --- | ---------- | -------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 1   | cx7        | Set up the LSP connection  | Connect supplied client; read configuration; advertise supplied LSP schema | Inspect the invoice project with Read; advertise LSP in the model request |
| 2   | gz6        | Find the implementation    | didOpen; definition routing and tool results                               | Follow invoice_total to pricing.total and read the implementation         |
| 3   | rb6        | Find the affected callers  | References routing with includeDeclaration true                            | Return pricing callers across checkout/reporting, excluding preview.total |
| 4   | bn2        | Keep the analysis current  | Successful Write sends full didChange with increasing per-file versions    | An edited import changes the definition target without a server restart   |
| 5   | ql9        | Change an API across files | Combine stages 1-4 with the existing Read, Write, Bash and agent loop      | Migrate pricing and its callers, leave preview unchanged, and pass tests  |

Stage one establishes the roles before any implementation. Each of the first
four stages introduces one learner-owned behavior. Descriptions stay under 350
prose words. Setup has no protocol payloads; definition lookup shows its two
messages together. Synchronization remains its own stage to show why a server
can have stale text before the capstone uses several edits and follow-up queries.

## Supply the connection

[The helper](../extension_helpers/README.md) owns server startup, framing,
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
IDs ls1, ir2, hv2 are retired, not repurposed. All five stages use backend-generated
IDs; ql9 now grades the migration capstone instead of asynchronous diagnostics.
Rename remains outside the built-in LSP tool's course scope.

The fixture recognizes the documented invoice project; it is not a Python
analyzer. Pyright independently verifies navigation and the actual Price migration.
LSP supplies a persistent analysis connection and structured navigation. Project
tests check behavior, while separate grader assertions check the new pricing API
and unchanged unrelated files.

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
