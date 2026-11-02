# LSP revision verification

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

- Compile and exercise C++, C#, Rust and Zig starter clients in their supported
  build environments. Their toolchains/dependencies were unavailable locally;
  inclusion and generated-starter parity do not establish runtime correctness.
- Live-model reliability and the existing 100-run live flakiness check with a
  valid CODECRAFTERS_SECRET_OPENROUTER_API_KEY.
- A learner pacing trial, especially the first navigation stage and the coordinated
  API migration in the finale.
- Deploy matching course content and tester registration with the allocated
  stage IDs cx7, gz6, rb6, bn2 and ql9. These use the first five slugs supplied
  from the backend generator on 2 November 2026. No publication was performed.

Scripted integration runs prove the tool wiring and migration checks. They do not
prove that a live model will reliably choose the required navigation and edits.
