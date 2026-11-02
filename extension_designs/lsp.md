# Language Server Protocol - extension design

**Status:** An introduction followed by five graded stages. Current IDs remain provisional; official allocation
and publication are deferred. No production release is authorized.

**Promise:** Give your existing agent precise code navigation before an edit and
language-server feedback afterward, so it can repair a caller missed during an
API change.

**Prerequisites:** The base agent loop, Read, Write, and Bash. Skills is not needed.
The learner builds an agent integration, not a language analyzer or editor.

## Introduce the server and helper before coding

The extension description is the learner's introduction. It explains what a
language server analyzes, how it connects to the existing agent loop, and which
parts are supplied. This is reading material before the first implementation
stage. Keep the server explanation and request/result route in this extension
introduction and repeat the essential context in stage one, where learners see
it while taking the course. The setup stage then gives implementation
instructions and checks the connection and tool schema.

The introduction shows the complete route from a model tool call through the
learner's handler and supplied connection to the language server, and back as a
tool result. The helper owns starting the server and delivering messages. The
learner owns document contents, queries, synchronization and model-visible results.

It also shows pricing.py and checkout.py from the test-supplied invoice project,
including the aliased import. These are files the agent analyzes in its test
working directory, not extra files the learner must build into the agent.

Stage one links to the example files, connects the supplied client, retrieves
the extension-to-language mapping, and advertises the supplied tool schema.
It uses the existing Read tool to inspect the example; it does not require an
LSP tool handler, file URIs, coordinates, or document messages. Every LSP test
supplies a connection; learners construct the client without an environment check.

Stage two focuses on following invoice_total to pricing.total. It reuses the
connection and schema, adding only document opening, definition routing, and
matching tool results. It introduces notify and request payloads when needed.

The same invoice project continues through all five stages. The introduction
previews the destination: changing pricing.total from integer cents to a Price
TypedDict leaves a caller returning an object where an integer is expected.
The final stage supplies the error feedback that lets the agent repair it.

```text
Before: Write saved checkout.py. The caller still returns Price as int.
After:  Write reports the return-type error.
        Agent changes return amount to return amount["cents"].
        Write receives an empty diagnostic publication.
```

The first attempted caller edit is fixed in the demonstration. It is not a claim
that a live model will spontaneously make this mistake. The scripted model only
requests repair after the preceding Write result contains an error diagnostic.
A separate ordinary prompt lets learners try the completed agent with a live
model, where the first edit may already be correct.

Search is a brief motivation, not an implementation stage. Searching for total
finds unrelated preview code and imports, while the alias invoice_total needs
interpretation. Do not claim grep cannot solve it. The API migration and resulting
type error provide the main reason to use language analysis.

## Five short stages

| #   | Current ID | Stage                        | New implementation                                                         | Visible evidence                                                          |
| --- | ---------- | ---------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| 1   | lc1        | Set up the LSP connection    | Connect supplied client; read configuration; advertise supplied LSP schema | Inspect the invoice project with Read; advertise LSP in the model request |
| 2   | df3        | Find the implementation      | didOpen; definition routing and tool results                               | Follow invoice_total to pricing.total and read the implementation         |
| 3   | rf4        | Find the affected callers    | References routing with includeDeclaration true                            | Return pricing callers across checkout/reporting, excluding preview.total |
| 4   | sy5        | Keep the analysis current    | Successful Write sends full didChange with increasing per-file versions    | An edited import changes the definition target without a server restart   |
| 5   | dg6        | Catch an error after editing | Process diagnostic publications; return fresh feedback from Write          | Partial API migration reports an error, drives repair, and clears         |

The introduction establishes the roles before any implementation. Each stage
introduces one learner-owned behavior. Descriptions stay under 350 prose words.
Setup has no protocol payloads; definition lookup shows its two messages together.
Synchronization remains its own stage to keep diagnostics bounded and show why
a server can have stale text.

## Supply the connection

[The helper](../extension_helpers/README.md) owns server startup, framing,
initialization, response IDs, notification queuing, and process cleanup. Native
starter clients for all ten course languages connect to its supplied URL. The
course starts it automatically; no manual server installation is required for
graded tests. Its local HTTP interface is course scaffolding, not LSP.

The learner still constructs didOpen, definition, references and didChange
messages, tracks document versions, handles diagnostics and supplies model tool
results. Neither the helper nor the server runs the agent or chooses a repair.
Read and Write remain existing base-course tools; LSP navigation joins their
existing dispatch and diagnostic feedback extends Write's result.

The standalone helper supports an independently installed server through the
same .lsp.json command/args/extensionToLanguage shape. Transport internals and
manual installation are optional material. No plugin manager is required.

## Scope and fidelity

Navigation and diagnostic feedback are documented product capabilities:
[Claude Code's TypeScript plugin](https://claude.com/marketplace/plugins/typescript-lsp).
Document opening, changes, definition requests and diagnostic notifications follow
[Microsoft's LSP overview](https://github.com/microsoft/language-server-protocol/blob/gh-pages/_overviews/lsp/overview.md).
The prior independent product check used Claude Code 2.1.266. Retain a separate
native-product smoke check; do not confuse our structured Write result with the
product's diagnostic attachments.

Hover, standalone initialization and response-reading stages are removed. Their
IDs ls1, ir2, hv2 are retired, not repurposed. Existing df3/rf4/sy5/dg6 IDs retain
their behaviors. Rename remains outside the built-in LSP tool's course scope.

The fixture recognizes the documented invoice project; it is not a Python
analyzer. Pyright independently verifies navigation and the actual Price migration.
Static diagnostics can also be obtained by running a checker through Bash. LSP
adds a persistent analysis connection, navigation and structured edit feedback.
Clean diagnostics do not prove business correctness; project tests remain useful.

For deterministic grading, the fixture publishes once per open/change except the
missing-publication case. Real servers determine publication timing. Ignore stale
versioned reports; accept unversioned reports in arrival order. They cannot prove
which edit was analyzed. A bounded wait must report missing feedback as an error.

Deferred: completion, incremental synchronization, workspace indexing by the
client, cancellation, arbitrary shell-edit watching and plugin discovery.

## Verification and release gates

The tester runs the actual agent HTTP/tool loop and a real stdio child, with
protocol, tool-result and final-file assertions. Each stage prints evidence of
its useful outcome. Broken-client regressions cover lost results, wrong positions,
missing declaration context, stale server text, cached/unversioned feedback and
false success after a timeout. Separate helper tests cover startup/framing so
those checks no longer inflate graded stages.

Regenerate recorded output when cases or prompts change. Verify the reference
agent against Pyright and inspect the before/after migration through the CLI.
Check starter helper parity and course/tester stage registration together.

The revised design still needs a learner pacing trial and repeated live-model
runs with valid CODECRAFTERS_SECRET_OPENROUTER_API_KEY before publication.
Deterministic scripted runs establish integration, not live-model reliability.
Official stage allocation and deployment remain separate release steps.

See the [local verification record](../extension_helpers/verification.md) for
passed checks and remaining release checks.
