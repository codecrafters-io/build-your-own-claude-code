# Language Server Protocol - extension design

**Status:** Runnable locally with the companion `claude-code-tester` checkout.
All eight stages, a controlled stdio server, a standard-library Python reference
agent, and recorded offline fixtures are implemented. All 26 cases passed ten
consecutive offline runs. Live-model trials and model-backed prose lint remain
outstanding because no OpenRouter key is configured. This is ready for local
implementation and testing, with publication checks still pending.

**Extension:** `lsp` - Language Server Protocol

**Axis:** Give the agent the same symbol information an editor uses, then keep
that information correct while the agent edits code.

**Prerequisites:** The base agent loop, `Read`, `Write`, and `Bash`. No
dependency on Skills, subagents, interactive mode, or a particular
implementation language.

## What the learner builds

A small LSP client inside the agent. It starts one configured server, speaks
JSON-RPC over stdio, and exposes one tool with several operations. The language
server does the language analysis; the learner implements transport, document
state, and the bridge to the agent loop.

| #   | Slug  | Stage                            | Difficulty | New work                                                                        | Observable result                                                                 |
| --- | ----- | -------------------------------- | ---------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 1   | `ls1` | Send the initialization request  | easy       | Start the configured process, serialize and frame one request                   | Server receives a valid initialize frame with the correct project URI             |
| 2   | `ir2` | Read the initialization response | medium     | Buffered frame reader, response matching, notifications, handshake and shutdown | Initialization finishes before the first model request; connection closes cleanly |
| 3   | `hv2` | Look up a symbol's type          | medium     | LSP tool, file URIs, document opening, hover                                    | Server-only documentation reaches the model                                       |
| 4   | `df3` | Go to a definition               | easy       | Definition routing and location results                                         | An alias resolves to the original definition                                      |
| 5   | `rf4` | Find a symbol's references       | easy       | References routing and declaration flag                                         | All semantic references reach the model, without name-based filtering             |
| 6   | `sy5` | Keep the server up to date       | medium     | Document versions and full-text change notifications                            | A query after a write uses the new document                                       |
| 7   | `dg6` | Read diagnostics after an edit   | medium     | Notification storage, version matching, feedback after writes                   | The model sees a new error and then its removal                                   |
| 8   | `rn7` | Rename a symbol across files     | hard       | Applying a WorkspaceEdit across files and UTF-16 ranges                         | The intended symbol changes; aliases and unrelated code survive                   |

The original opener combined process management, sending, receiving, and the
full lifecycle. It is now two stages: first write one real request, then
implement a reader and complete the handshake. The easy opener reuses subprocess
experience from Bash and teaches only the sending side of framing. The medium
second stage introduces partial reads, notifications, and matching responses.
Both pieces remain in the completed client; no temporary tool or CLI flag is
introduced.

Stage 3 adds the first useful model-facing operation. Definition and references
are deliberately easier because they reuse the connection and document-opening
code. Stages 4 and 5 must require the result to reach the model, not just a
matching method name in a server log. The final stage earns its difficulty
through applying edits, rather than through a longer prompt.

## One project, increasing capability

The sample project is in [lsp_exercise](lsp_exercise/README.md). It calculates
an invoice in cents. The implementation is Python regardless of the language
used to build the agent, just as the base stages operate on supplied project
files.

- `pricing.py` defines `total(price: int, quantity: int) -> int`.
- `checkout.py` imports it as `invoice_total` and incorrectly passes `"250"`.
- `reports.py` calls the original function twice on one line.
- `preview.py` defines an unrelated `total` and mentions the name in a comment
  and string.

The payoff is concrete: text search misses the imported alias and includes the
unrelated function. A correct rename changes the original definition, its import
specifiers, and the unaliased calls. It leaves the `invoice_total` local alias
and its call unchanged. Server behavior, not a client-side spelling rule,
determines these edits.

Each graded stage starts in its own fresh workspace. The narrative project is
shared; passing one stage must not depend on files modified while running a
previous stage.

The last stage's graded task is a rename with a supplied position and new name.
The longer prompt in the sample README combines diagnosis, repair, and rename as
an optional demonstration, not another stage with no new implementation work.

## Protocol contract

Target the relevant subset of **LSP 3.17**. Link learners to the standard, but
include the messages needed for each stage in its description. Do not require
reading the whole specification.

### Configuration and lifetime

`.lsp.json` contains `command`, `args`, and `languageId`. This is a course
convention, not a standard LSP configuration file or a claim about Claude Code's
configuration format. The harness supplies an executable and arguments; learners
do not install a Python server or parse a shell command. Spawn it directly with
piped stdin/stdout and the project as cwd.

When the file exists, start the server and send initialize before the first LLM
call. From stage 2 onward, also wait for its response and send initialized
before calling the LLM. The outbound request makes stage 1 observable without
inventing a temporary CLI flag or a model-facing status operation. No
configuration means no server; the base course remains usable.

Stage 1 deliberately stops at sending. Its fixture sends a small initialization
response, with no extra notifications, so a client that has no reader yet cannot
fill the stdout pipe. At the end of the run, the learner closes the child's
stdin and waits; this fixture exits on EOF. It must also accept the full
initialized/shutdown/exit lifecycle, so a completed client still passes stage 1.
Do not terminate the fixture immediately after the first request or require the
absence of later protocol messages. Stage 1 checks outbound framing and process
cleanup, not response reading or model-request timing relative to the response.

From stage 2 onward, one process lives for the complete `-p` invocation. The
order is `initialize` request, matching response, `initialized` notification,
document operations, document closes, `shutdown` request and response, then
`exit` notification. Initialization requests include `processId`, `rootUri`, and
`capabilities`. Request IDs are unique within that connection. All responses are
matched by ID, not by their arrival position. An initialization error must stop
the run and clean up the process; a graceful shutdown handshake is required only
after successful initialization.

When comparing server and model events, check that the initialization response
was sent before the first model request, and that the server receives
`initialized` before any document operations. Do not require its event log to
have recorded `initialized` at the instant the model request arrives: that
notification has no acknowledgment, and process scheduling can change when it is
observed.

The reader must accept partial headers, partial bodies, and multiple frames in a
read. `Content-Length` counts UTF-8 bytes. Separate protocol output from stderr.
EOF during a pending response is an error. Unknown notifications can be ignored.
The fixture never sends server-to-client requests, dynamic registrations, or
progress requests.

### Document and tool state

Convert paths to absolute, encoded file URIs through a URI library. A path with
spaces and its encoded URI must resolve to the same document key. The fixture
uses ordinary files, not symlinks. `didOpen` carries complete text and version
1; later writes use strictly increasing per-document versions. Notifications
have no ID and receive no response.

The fixture advertises `textDocumentSync: {openClose: true, change: 1}`, hover,
definition, references, and rename. The same executable serves every stage.
Clients can save these capabilities without building a general negotiation
framework or implementing later operations ahead of their stage. All source
files used in these exercises share the configured language ID; routing
mixed-language projects is deferred.

The LSP tool's operations are `hover`, `definition`, `references`,
`diagnostics`, and `rename`. All require a path. Except for diagnostics, they
require zero-based `line` and UTF-16 `character`. References additionally
requires `include_declaration`; rename requires `new_name`. Names are
illustrative: accept equivalent tool names and argument conventions when the
resulting LSP messages are correct. The tool bridge belongs to the course; these
operation strings are not protocol method names.

Hover uses `MarkupContent` with plaintext or markdown, or `null`; legacy
`MarkedString` forms are outside the fixture. Definitions use `Location`,
`Location[]`, or `null`; clients do not advertise link support. References use
`Location[]` or `null`. Passing JSON results through to the model avoids a
formatting exercise.

### Diagnostic freshness

The fixture uses push diagnostics, not a made-up diagnostics request or LSP 3.17
pull diagnostics. At stage 7, clients advertise
`textDocument.publishDiagnostics.versionSupport: true`. The fixture guarantees
one complete, versioned diagnostic publication for each document open and
change, including empty publications for valid files. The same guarantee holds
after rename edits in stage 8.

This guarantee is stronger than LSP in general, where versions are optional and
publication timing is server-dependent. It deliberately keeps this course from
becoming an exercise in supporting every server's diagnostic policy. A
real-server compatibility pass must separately check that server's behavior; do
not claim universal support.

Store the newest publication per URI. A publication replaces the list, rather
than appending to it. Before returning diagnostics, match its version to the
client's current document version. Preserve notifications that arrive while
waiting for a hover or another response. A delayed older publication must not
replace a newer one.

On a successful Write, synchronize an already-open document or open a previously
unopened one with its new contents, then include that version's diagnostics in
the write result. A reasonable bounded timeout must return an explicit
diagnostic error, never an empty success list. No fixed sleeps or quiet-period
heuristic.

One sequential message dispatcher is sufficient for this exercise; an async
reader is also valid. Keep draining messages when waiting for a notification,
even if an ordinary response arrives. A notification may arrive before the
client begins waiting for it.

### Rename boundaries

The test server returns `WorkspaceEdit.changes` containing non-overlapping
ranges in existing workspace files. No `documentChanges`, resource operations,
prepare-rename, annotations, or server-initiated `workspace/applyEdit`. Do not
advertise capabilities for those features.

Apply each file's edits against its original text in descending position order.
A shared write helper should synchronize changed files and return diagnostics,
regardless of whether a change originated in Write or Rename. Prepare all
replacement texts before beginning disk writes; atomic recovery from disk
failures is not a stage requirement.

Tests must include multiple edits on one line, different replacement lengths,
and UTF-16 positions after a non-BMP character. The Unicode fixture is justified
by protocol functionality; the sample project itself stays ASCII. Prefix text
before an edited range must survive byte-for-byte.

## Tester implementation requirements

The companion `claude-code-tester` repository now contains
`internal/lsp_manager/`, one registered Go function per stage, and a shared
stage runner. The tester binary dispatches `--lsp-fixture` to its stdio server.
It reuses the existing model-request recorder, with a first-request timestamp
for the initialization ordering check.

The fixture should behave like a small state machine, not accept arbitrary
messages and hand back canned success. Record process instance IDs, requests,
notifications, opened text, and versions in a harness-owned event log. Keep that
log and answer data out of the learner workspace; don't put server-only tokens
into readable project files or pass them in visible arguments.

Use one tiny, documented project shape. The fixture may implement only that
shape; do not pretend it is a production Python analyzer. It must derive changed
hover information, diagnostics, and rename ranges from its maintained document
state. A live language server should be used for an additional compatibility
check before shipping.

| Stage | Required cases                                                                                                                                                                                                               | Reject this shortcut                                                                                                               |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `ls1` | Configured command, arguments and cwd; valid framed initialize; correct process ID and encoded root URI; no-config base regression; cleanup on EOF or full shutdown                                                          | Ignore configuration, write JSON without a header, count characters as bytes, or leave the server running                          |
| `ir2` | Initialize response precedes the first model request; initialized precedes document operations; split frames; coalesced notification/response; non-ASCII log text; orderly shutdown; initialization error; EOF while waiting | Send initialized without reading the reply, assume the next frame is a response, count characters as bytes, or wait forever on EOF |
| `hv2` | Correct URI and supplied position; one open per URI; encoded spaces; server-only random token in the next tool result; null hover; JSON-RPC error                                                                            | Read project text and answer without an LSP request, or send a request but discard its result                                      |
| `df3` | Imported alias; unrelated same-name definition; single and multiple locations; null result                                                                                                                                   | Grep by the visible name or return only the first location                                                                         |
| `rf4` | Aliased and unaliased uses; both declaration settings; empty result; shuffled locations                                                                                                                                      | Include comments or unrelated names, filter out aliases, or ignore includeDeclaration                                              |
| `sy5` | Query/write/query/write/query in one process; unopened file; failed write                                                                                                                                                    | Restart to pick up disk changes, reopen an open URI, or send a change before the write succeeds                                    |
| `dg6` | Initial error; changed error; repaired file; interleaved notifications; old version after new; notification before waiting; absent publication with bounded failure                                                          | Return stale errors, accumulate old diagnostics, or call a timeout an empty success                                                |
| `rn7` | Definition, imports and callers changed; alias and decoy bytes preserved; unsorted edits; several edits on one line; non-BMP prefix; null edit; final synchronization and diagnostics                                        | Ask the model to rewrite files or replace every occurrence of a name                                                               |

For each case, separate the server's observations from assertions about what
reached the model. An actual protocol request and its actual result must both be
visible. Assert at the first subsequent request containing the matching
tool-result ID, not across the entire conversation: older tool results correctly
remain in history. For Write's automatic diagnostics, inspect the matching Write
tool result.

Use explicit positions in graded prompts. The invoice module names and positions
stay fixed for debuggability. Server-only documentation tokens vary per
invocation, and separate cases vary reference layouts and ordering without
requiring the model to infer a column. Test protocol invariants and file state;
avoid requiring a particular prose answer. Reference sets should be compared
without ordering. Sample stdout is illustrative, as in the base course.

Where practical, replay deterministic model tool calls against a reference
client to exercise framing and state without paid model calls. Also run
end-to-end prompts with the course's actual model. Record and investigate flaky
failures rather than widening an assertion until it passes.

## Scope and shipping checks

This is a course-sized LSP client, not a general editor. Completion, indexing
implementation, incremental diffs, multiple servers, cancellation, shell file
watching, and whole-workspace diagnostics are deferred. Rename applies the
standard's workspace edits; it is not a claim that Claude Code exposes the
identical operation or configuration.

The fixture, reference client, all eight stages, and offline regressions are
implemented. Before shipping, run repeated live-model trials, the complete
base/Skills live scenarios, and the model-backed prose check. Local offline
results and the pinned real-server smoke check below do not substitute for those
publication checks.

## Authoring-guidelines audit

Reviewed against CodeCrafters'
[Building your challenge](https://docs.codecrafters.io/contributors/authoring-challenges/building-your-challenge),
[Writing stage instructions](https://docs.codecrafters.io/contributors/authoring-challenges/writing-stage-instructions),
and
[Planning your challenge](https://docs.codecrafters.io/contributors/authoring-challenges/planning-your-challenge)
guides, plus the SDK's Review Course Extensions rubric.

The language also follows the existing
[agent-loop](../stage_descriptions/base-04-ff2.md),
[skill invocation](../stage_descriptions/skills-02-jd8.md), and
[skill arguments](../stage_descriptions/skills-03-wd2.md) stages: introduce a
concrete example, explain what the program is missing, and walk through the
change. The prose revision preserves every fenced protocol example, test
command, and expected output.

| Guideline                                                            | Application here                                                                                                                                                                          | Status                                                   |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| A short objective followed by explanation, tests, and optional notes | Every stage has one opening sentence, explanatory sections, Tests, and at most three Notes bullets. Its marketing text matches the hook exactly.                                          | Checked locally                                          |
| Show how to invoke the program and what to expect                    | Every Tests section contains a literal command and an example of the expected protocol message, tool result, or changed file.                                                             | Checked locally                                          |
| Keep early work approachable and split substantial steps             | Sending and receiving initialization are separate stages. The opener is rated easy. The buffered reader remains medium because its actual work includes partial frames and notifications. | Provisional until learner trials                         |
| Give every registered stage a corresponding tester case              | All eight slugs are registered in the tester and match its local copy of the course YAML. Each stage has recorded output and executable checks.                                           | Passed offline                                           |
| Test the tester against a reference implementation                   | The reference client passes all 26 controlled cases and five broken variants are rejected. A Pyright 1.1.414 smoke check passes for the overlapping transport and query features.         | Passed offline and smoke checks, live trials outstanding |

The planning guide recommends keeping the first two or three challenge stages
easy. This extension follows the completed base course, so its learners already
have an agent loop and subprocess execution. Keep the honest medium rating for
the reader rather than relabeling it as a five-minute task. The two-part opening
is retained as requested. Revisit its pacing after a learner implements it.

The website describes stage instructions as inline `description_md` in YAML. The
checked-out SDK schema rejects that property on stages, and its stage editor
loads `stage_descriptions/*-<slug>.md`. Keep this repository's Markdown-file
convention rather than duplicating content into an unsupported key.

The review rubric's literal-output requirement is applied to deterministic
protocol messages, recorded tool results, and file contents. Model replies
retain flexible wording, as the same rubric requires. The grader must not
compare the LLM's final answer for exact equality. Paths, process IDs, request
IDs, and JSON whitespace in examples are illustrative unless explicitly fixed by
the protocol. Match decoded values and request relationships instead of
hardcoding the displayed frame.

The first tester case for each stage must reproduce its described example, with
any smaller fixture variant spelled out. The definition example's checkout call
is on line 2, whereas the downloadable invoice project's call is on line 4. The
references example uses the latter layout. Log the files and positions actually
used so this difference is visible to the learner. The fixture unit tests pin
the displayed checkout reference and diagnostic ranges. The first case of
references omits `reports.py`, matching the two-location example. Other cases
include that module and reversed results.

The model-backed CI prose check has not run. The executable cases and offline
reference runs now exist, but local mechanical checks do not substitute for that
prose review or live-model trials.

## Local validation

The course YAML parses, all eight slugs are unique and resolve to stage files,
and every JSON example parses. Learner-facing prose outside code blocks is
between 200 and 350 words per stage. The sample's documented positions and local
Markdown links were checked, and its Python sources parse.

The original sample produces the intended single failing checkout test:
`'250250' != 500`. In a temporary copy, changing the argument to an integer and
applying the rename edits from the end of each file makes all three tests pass
and checkout print `500`. The local alias and the exact bytes of the unrelated
preview file remain intact. These checks validate the sample independently of
the client and server integration checks below.

The SDK source is available in a neighboring checkout. Validation against its
JSON Schema and stage-solution naming rules passes. Prettier's 80-column prose
check also passes, as do local checks for hook/marketing equality, one-sentence
hooks, heading levels, literal test commands and expected behavior, Notes bullet
counts, plural stage references, and semicolon-free prose. The new 128-byte
frame and symbol ranges were checked against serialization and the example text.
Fixture unit tests and reference-stage runs now confirm the displayed symbol
ranges and diagnostic feedback.

The course SDK CLI is not installed locally. Full shared CI, model-backed prose
lint, and live LSP/LLM trials have not run.

### Runnable tester checks

In the `claude-code-tester` checkout:

```sh
make test_lsp
make test_lsp_offline
make record_lsp_fixtures
```

`make test_lsp` runs fixture helper tests, the recorded output comparison, YAML
registration, a sending-only stage-one client, and five deliberately broken
clients. The rejected clients discard hover results, omit synchronization, apply
edits forward, interpret UTF-16 columns as code points, or turn absent
diagnostics into an empty success list. Temporary mutations of UTF-16 counting,
array cardinality, and alias-preserving rename helpers were also rejected by
their focused tests.

`make test_lsp_offline` drives the real agent HTTP/tool loop against a
deterministic model and the real stdio fixture. Its 26 cases passed ten
consecutive runs. The live `TestStages` scenario and
`make test_lsp_with_users_code` use the existing OpenRouter proxy and the same
stage checks and normalized output fixture. They still require a trial with
`CODECRAFTERS_SECRET_OPENROUTER_API_KEY`.

`go test -count=1 -skip '^TestStages$' ./...` passes the offline suite,
including existing Skills and assertion unit tests. This command deliberately
excludes the existing paid-model scenarios. The no-config case protects the base
prompt path, but the complete base and Skills live regressions remain
outstanding.

The separately installed Pyright 1.1.414 smoke check passes initialization,
hover, imported-alias definition, references, rename responses, and shutdown.
Reproduce it with the pinned install and `make test_lsp_with_pyright`
instructions in the tester README. The smoke check does not apply its rename
response or test automatic diagnostic feedback. Pyright can omit diagnostic
versions, return `documentChanges` for rename, and treat an alias call as a
reference to the local alias. Those behaviors differ from the controlled
exercise guarantees. The reference reader ignores unversioned publications and
returns a bounded error when current-version diagnostics do not arrive.

No tester release has been tagged or published. Local execution does not require
a release; the hosted challenge does.

## Sources

- [LSP 3.17 base protocol and message ordering](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#baseProtocol)
- [Initialization](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initialize)
- [Document synchronization](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_synchronization)
- [Hover](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_hover),
  [definitions](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition),
  and
  [references](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_references)
- [Push diagnostics](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_publishDiagnostics)
- [Rename](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_rename)
  and
  [workspace edits](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspaceEdit)
