# LSP revision verification

## Optional connection setup - 4 November 2026

All ten supplied clients now provide an environment factory. An absent
`CODECRAFTERS_LSP_URL` returns no client; a configured URL initializes the client
and fetches its language mapping. Existing required initialization APIs remain
available. Stage 1 uses the factory, Stage 2 enables the tool and prompt guidance
only for a configured connection, and Stage 3 explains access to optional clients.
Every LSP course test still supplies a connection.

Stage 1 states that course tests provide the connection automatically and directs
learners to `codecrafters test`, keeping helper and environment-variable details
in the optional advanced guide.

- Native checks pass for all ten factories: unconfigured startup skips the helper,
  configured startup fetches the mapping once, and 8 KiB responses are preserved.
  Empty URLs, unreachable helpers, and failed configuration fetches remain errors.
  C++ was compiled and exercised separately in a temporary Ubuntu container.
- C and Zig error-body and recovery regressions pass. Strict TypeScript checking
  passes with the optional-client guard. The exact Stage 1 Zig setup compiles
  and exits successfully without a connection.
- All ten starter and compiled client copies match. All 60 stage/language
  variants render with valid JSON examples. Revised Python setup and tool
  registration, plus Zig client access, were inspected in the browser.
- Python syntax, Go and Zig formatting, and diff whitespace checks pass.
  No publication was performed.

## Stage 6 capstone walkthrough - 4 November 2026

Stage ql9 shows one complete task prompt, a table of expected results, and a
shorter integration checklist using Stage 5's shared version map. Tests focus
on saved behavior, current navigation positions, unchanged files, and real Bash
output. The lesson ends with the completed agent's capabilities.

- All 60 stage/language variants render with valid JSON examples. The single
  task prompt matches the companion tester after line wrapping, and both Python
  API examples are unchanged.
- The revised lesson was inspected in the browser. Diff whitespace checks pass.
  This revision changes documentation only. No publication was performed.

## Stage 5 synchronization walkthrough - 4 November 2026

Stage bn2 explicitly replaces Stage 3's URI set with a version map shared by
navigation and Write. One ordered flow covers saving, notifying, recording the
version, and returning the tool result. The import example and Tests section
are shorter, with both open- and closed-document writes retained.

- All 60 stage/language variants render with valid JSON examples. The complete
  `didChange` payload and tester prompt are unchanged.
- The revised lesson was inspected in the browser. Diff whitespace checks pass.
  This revision changes documentation only. No publication was performed.

## Stage 4 references walkthrough - 4 November 2026

Stage rb6 has a shorter motivation, explicit replacements for the tool
description and system-prompt guidance, and a checkpoint leading into edit
synchronization. Its Tests section describes coverage without repeating the
worked location array.

- All 60 stage/language variants render with valid JSON examples. The Stage 4
  tool arguments, server request, and worked response are unchanged.
- The revised lesson was inspected in the browser. Diff whitespace checks pass.
  No client or tester behavior changed, and no publication was performed.

## Stage 3 definition walkthrough - 4 November 2026

Stage gz6 distinguishes the model's tool call from the server request and
explains why the handler sends source contents before the model reads the
returned implementation. Document tracking now precedes lookup instructions,
with concrete per-URI sets and named payloads in all ten languages. The Tests
section states the expected behavior without an escaped file-content fixture.
C and Zig client links point to this repository's supplied clients.

- The exact state declarations and handler examples compile and run with all
  ten supplied clients. Across two source URIs and three definition requests,
  each URI opens once and every result retains the server's location JSON.
- A failed Python `didOpen` leaves its URI unopened. Strict TypeScript checking
  passes. The Zig example retains owned URI strings after each input is freed.
- All 60 stage/language variants render with valid JSON examples. Python and
  Zig previews were inspected in the browser. Diff whitespace checks pass.
- This is a lesson-only revision; the tester's successful-definition scope is
  unchanged. No publication was performed.

## Stage 2 tool-call exercise - 4 November 2026

Stage iy3 now exercises the temporary LSP handler. Its prompt requests
`goToDefinition` at checkout's alias call, and the checker requires a response
to reach the model with the matching call ID. A placeholder passes without any
navigation request. An agent that already implements definition lookup still
passes with the real server result.

- The lesson shows a concrete call, explains why positions identify symbols,
  and uses a tool description focused on definition lookup. Write guidance now
  appears in Stage 5. The shared schema and all ten compiled copies match.
- Integration checks accept plain-text and JSON-serialized placeholders and
  reject wrong call IDs, incorrect responses, missing follow-up requests, and
  unhandled calls. Disabling placeholder validation makes all four negative
  regressions fail.
- The full offline companion tester suite passes with
  `go test -count=1 -skip '^TestStages$' ./...`, including all six stages and the
  existing navigation and synchronization regressions. Recorded output was
  regenerated, and the verified changes were applied to the companion checkout.
- All 60 stage/language variants render with valid JSON examples. The revised
  Python lesson was inspected in the browser. Diff whitespace checks pass in
  both repositories. No publication was performed.

## Client initialization - 4 November 2026

All ten supplied clients now fetch the language mapping during initialization
and expose it on the client. JavaScript and TypeScript use `LSPClient.create()`;
C# uses `LSPClient.CreateAsync()`. The other languages use their constructor or
initialization function. Stage 1 and the later setup references no longer ask
learners to call `configuration` or parse its response. Client download links
point to the matching starter templates in this repository.

Stage 1 now assumes the supplied client is already in the starter repository.
Each language's initialization section links directly to the current client
file and states its destination path if the supplied copy is missing or outdated.
Mapping access is introduced beside `didOpen` in Stage 3, where it is first needed.

- Native runtime checks pass for all ten clients: initialization exposes a
  configured TypeScript mapping, fetches it once before tool requests, and stops
  on a failed fetch. Existing 8 KiB response checks still pass. Rust also passes
  all four base-URL variants.
- `verify_clients.py` now covers nine clients, including C# and Zig, in CI. C++
  was compiled and exercised separately with CPR in a temporary Ubuntu container.
  C and Zig error-body and recovery checks pass with initialized clients.
- The six-stage offline reference exercise, connection without advertisement,
  advertisement without navigation, and stage registration checks pass in a
  temporary companion tester copy using the updated Python client and mapping
  property. The original companion checkout was left unchanged.
- Strict TypeScript checking, Python syntax, all ten starter/compiled-client
  comparisons, and diff whitespace checks pass. All 60 stage/language variants
  render with valid JSON and matching client links. Python and JavaScript setup
  previews were inspected in the browser.
- After simplifying the lesson, all 60 variants render with valid JSON, all ten
  client download links resolve, and the exact Stage 1 Go and Zig
  examples compile without unused-local errors. The revised Python setup and
  definition lesson were inspected in the browser.
- All ten direct download URLs were fetched and matched the current starter
  client files.

No publication was performed. The earlier dated sections below describe previous
client APIs and verification coverage.

## References and synchronization scope - 3 November 2026

Stage rb6 now requires reference arrays, including an empty array, without adding
null-result, unreadable-file, unsupported-extension, or client-error handling.
Stage bn2 now covers successful writes to supported Python files. Its description
keeps save-before-notify ordering, increasing versions, and synchronization for
files that have not been opened. Write failures and synchronization recovery are
outside the exercise.

- Removed the failed-directory-write case and its obsolete final-file-check
  exception. The repeated-version and write-before-open cases remain.
- A new integration regression passes Stage bn2 with an agent that cannot convert
  failed tool calls into error results. Existing stale-update regressions pass.
- Regenerated recorded output: all six stages pass, now 12 graded cases. The full
  offline suite passed with `go test -count=1 -skip '^TestStages$' ./...` in a
  temporary copy of the companion tester before applying the verified changes.
- Both revised descriptions render in browser previews. Their JSON examples are
  unchanged and their Markdown reference links resolve.

## Definition exercise scope - 3 November 2026

Stage gz6 now grades one successful alias lookup followed by Read. Array, null,
and server-error definition cases are removed. The description keeps the alias
example and explains document opening, URI encoding, position conversion, and
returning the location to the model. All ten client examples follow that flow.
Stage rb6's error-handling instruction now stands alone instead of referring to
handling that gz6 no longer requires.

- A new integration regression passes with an agent that accepts only a successful
  location object and cannot return tool errors. Existing regressions still reject
  wrong coordinates, a discarded definition result, and a missing Read result.
- The reference-agent sequence passes all six stages, now 13 graded cases. Recorded
  output was regenerated. The complete offline suite passed with
  `go test -count=1 -skip '^TestStages$' ./...` in a temporary copy of the companion
  tester before applying its verified changes to that checkout.
- All ten Stage 3 language variants render with resolved links and valid JSON.
  The example coordinates and Python snippets were checked; Python and Go views
  were inspected in a browser preview.

The dated sections below record earlier revisions, including earlier case counts.

## Setup split - 3 November 2026

The combined setup stage cx7 is replaced by two stages using the supplied slugs:

- dz5 connects the supplied client and reads configuration before the first model
  request. It passes without an advertised LSP tool.
- iy3 advertises the LSP schema in every model request and adds a temporary
  handler. It passes before navigation is implemented.

The later IDs remain gz6, rb6, bn2, and ql9, now numbered 3-6. Course registration,
description filenames, cross-references, the design, and the companion tester's
registration and course YAML agree on the six-stage order.

- The two setup descriptions have 400 and 431 prose words in the Python view.
  All ten client setup blocks and the tool schema are preserved. All 60
  stage/language variants render with valid JSON examples and resolved links.
  Both setup pages were inspected in Python and Go browser previews.
- New boundary regressions verify connection without LSP advertisement,
  advertisement without navigation, rejection of late configuration, and schema
  advertisement in subsequent model requests.
- All six stages pass the reference-agent offline sequence, now 16 graded cases.
  Recorded output was regenerated. The full offline suite passed with
  `go test -count=1 -skip '^TestStages$' ./...` in a temporary copy of the
  companion tester before applying its verified changes to that checkout.

The dated sections below record earlier revisions. Their stage counts and
numbering describe the pre-split course.

## Extension review fixes - 3 November 2026

- All five hooks match their marketing text. Every Tests section shows the
  tester's command and literal tool results or migration outcomes. References
  and synchronization have complete worked examples. Model instructions live
  in the system prompt, and all ten starter schemas match that revised example.
- The review skill's parser passes for every LSP stage. Per-language prose stays
  under 350 words. JSON examples parse, reference locations match the controlled
  server, and Python tokenization independently confirms their offsets.
- The companion tester requires complete Read results during setup and definition
  lookup. A broken Read handler is rejected. The capstone accepts reading and
  editing each file in turn, but still requires each Read before that file's
  first Write. Follow-up references use the definition's current position.
- The full offline suite passes with 15 LSP cases, including a migration that
  moves the definition with a comment. New regression tests were mutation-checked:
  breaking Read validation, per-file ordering, or dynamic coordinates fails them.
- The independent Pyright smoke check passes navigation, synchronization,
  migration, and all five invoice tests. The revised descriptions render in
  the local course editor.
- Full `course-sdk compile` remains unverified locally: the installed binary
  expects the older `starter-repository-definitions.yml` layout. The changed
  shared schema matches all ten compiled starter copies directly.

Checked locally on 2 November 2026. The companion tester contains the matching
five-stage registration, reference agent, fixtures, transport and regressions.

## Capstone revision verified

Stage ql9 now combines navigation, reads, synchronized edits, and Bash to migrate
pricing and both callers. It adds no diagnostic-handling requirement.

- Stage 5 feedback follow-up: the scripted sequence has 11 tool calls; the base
  loop stage has no prescribed cap (the reference agent allows 50 model requests).
  Stage bn2 already tests successive versions 2 and 3. The capstone writes to
  several URIs; it is not the first test of repeated edits to one document.
- The deliberate closed-file Pyright probe initially failed: reports.py was
  indexed by references but not opened, and Write left its reference ranges
  stale. Successful Write now reuses didOpen for supported closed files, while
  open-file writes retain didChange. The probe inserts two lines and verifies
  the report calls at zero-based line 6, columns 11 and 36. It passed after the
  fix. The controlled fixture now caches indexed text too, and a broken-agent
  regression rejects omission of closed-file synchronization.
- Pyright references on pricing.total return checkout's import token, not the
  aliased invoice_total call. Stages 3 and 5 explain inspecting returned files
  and preserving each server's results.
- test_invoice.py now checks both the returned cents object and the Price
  TypedDict contract. Before migration, its three behavior tests pass and two
  API tests fail; after migration all five pass. Both copies of the fixture
  match. Capstone prompts explicitly protect the test file.
- Re-recorded all five stages and ran the complete offline suite with
  `go test -count=1 -skip '^TestStages$' ./...` in a temporary copy of the
  companion tester. All packages passed, including the new regression.
- Inspected the staging course page: Share Feedback and Edit are UI controls.
  Its How to pass this stage section contains generic editor/submission steps;
  it is neither empty nor part of this repository's stage Markdown.

- Full offline suite: `go test -count=1 -skip '^TestStages$' ./...` with TESTER_DIR
  set to the updated companion tester checkout. All packages passed, including
  recorded output comparisons for all five stages (14 graded cases).
- The reference agent no longer collects diagnostic publications. Both capstone
  cases pass, including a server that never publishes diagnostics.
- Broken-agent regressions reject unsynchronized edits, a missed reporting caller,
  an unrelated preview edit, and lost Bash output. A separate regression rejects
  fabricated passing test output when reporting was never migrated.
- Equivalent pricing source using `dict(cents=...)` passes the behavior checks;
  the capstone does not require the scripted model's exact source text.
- The updated reference integration passed against installed Pyright: definition,
  references, edited-import synchronization, the complete Price migration, and
  all five invoice tests. Follow-up navigation sees the updated API and exact
  reference positions in the edited report.
- The rewritten stage renders in the local course editor. The stage ID remains
  ql9; the title is now "Change an API across files".

The checks below describe the earlier diagnostics design and remain historical
evidence for the helper and product integration, not the revised capstone.

## Earlier diagnostics design (historical)

- Complete offline tester suite from the updated companion checkout:
  `go test -count=1 -skip '^TestStages$' ./...` with TESTER_DIR set to that checkout.
  This includes 16 graded cases, recorded-output comparisons, ten broken-agent
  regressions and course/tester stage registration checks.
- Setup passes with an agent whose navigation handler is unimplemented. Setup
  regressions reject a missing configuration call, a missing LSP tool, and an
  incomplete required schema. Every LSP case supplies a connection; the reference
  agent constructs its client and advertises LSP without an environment check.
- `go test -count=1 -race ./internal/lsp_transport ./internal/lsp_manager`,
  including fragmented initialization, queued notifications, startup failure,
  cleanup and a configuration accessed through a project symlink.
- Configured-language regressions: the helper exposes a TypeScript extension
  map, rejects missing mappings, and the reference agent opens documents using
  the configured language ID while rejecting unmapped extensions. The offline
  suite and real Pyright migration also pass with configuration-based selection.
- `go vet ./...` in the tester and standalone transport build.
- Reference integration against Pyright 1.1.414: definition, cross-file
  references, definition after an edited import, the Price API migration,
  actual return-type diagnostics, repair and clearing. Repeated three times
  after fixing project-path canonicalization.
- Native Claude Code 2.1.266 with Pyright and a local scripted model: navigation,
  the API migration, diagnostic delivery before repair, synchronization and
  clearing. This uses the product's diagnostic attachment channel.
- Python, JavaScript, TypeScript, Go, C and Java starter clients round-tripped
  JSON through a local endpoint, including an 8 KiB response. Run
  `python3 extension_helpers/verify_clients.py` to repeat these checks. The
  LSP helpers workflow runs them in CI.
- All three invoice behavior tests passed initially and after the complete API
  migration. The partial migration failed only checkout's behavior test;
  reporting and unrelated preview behavior remained correct.
- All five stage descriptions stay under 350 prose words, excluding code blocks.
  Markdown formatting, JSON/YAML parsing, exact course/
  tester YAML equality, starter/template parity, shared transport source parity
  and diff whitespace checks passed.
- Setup and definition lookup render separately in the local course editor.
  The extension description gives a brief LSP overview. Setup defines a
  language server and LSP and shows the request/result route, so the detailed
  context is visible while taking the course. Setup identifies the supplied
  server/helper/client and lists
  file setup, configuration retrieval, and tool registration steps.
  The revised setup shows the JSON schema to add directly to the existing tool
  list and links to a guide for all ten clients. It explains the tester-provided
  connection and the empty
  configuration request body, and covers existing checkouts missing these files.
  Its Python example was exercised with the supplied client against a temporary
  local endpoint without a learner-side environment check. The inline tool
  schema matches the starter schema; registration no longer requires loading a
  schema file. Linked client files exist and match generated starters.
  Definition lookup reuses setup's connection without repeating
  configuration or tool registration.
- Stages two through five use complete helper request/notification envelopes.
  The definition response and matching model tool message, references request,
  changed-import synchronization, and diagnostic error/clearing examples were
  exercised through the supplied transport and controlled stdio fixture. All
  JSON examples parse; the diagnostic ranges and Write result examples match
  the fixture's actual publications. Diagnostics now has a numbered sequence
  covering draining, saving/synchronization, waiting, selection, and tool results.

The path fix matters: a helper initialized through a symlink must identify the
same physical project as the agent's document URIs. Otherwise real-server
reference results can omit callers even while the controlled fixture passes.

## Remaining release checks

- Live-model reliability and the existing 100-run live flakiness check with a
  valid CODECRAFTERS_SECRET_OPENROUTER_API_KEY.
- A learner pacing trial, especially the first navigation stage and the coordinated
  API migration in the finale.
- Deploy matching course content and tester registration with the allocated
  stage IDs dz5, iy3, gz6, rb6, bn2, and ql9. The setup split uses the first two
  slugs supplied on 3 November 2026; later stages keep their existing IDs.
  No publication was performed.

Scripted integration runs prove the tool wiring and migration checks. They do not
prove that a live model will reliably choose the required navigation and edits.
